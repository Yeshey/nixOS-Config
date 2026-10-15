# Use `sudo machinectl shell openclaw@openclaw` to connect to the openclaw container
# check the openclaw service:
# sudo nixos-container run openclaw -- journalctl _SYSTEMD_USER_UNIT=openclaw-gateway.service -f
# check the container:
# 

{ inputs, ... }:
{
  flake.modules.nixos.openclaw =
    { config, lib, pkgs, ... }:
    let
      hostConfig = config;
      home = "/var/lib/openclaw/home";
      proposals = "/var/lib/openclaw/config";
      checkout = "${home}/projects/nixOS-Config";
      openclawPkgs = import inputs.nix-openclaw.inputs.nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        overlays = [ inputs.nix-openclaw.overlays.default ];
      };
      secret = key: {
        inherit key;
        owner = "openclaw";
        mode = "0400";
        restartUnits = [ "container@openclaw.service" ];
      };
      ro = hostPath: { inherit hostPath; isReadOnly = true; };

      githubCli = pkgs.writeShellApplication {
        name = "gh";
        runtimeInputs = [ pkgs.gh-token pkgs.jq ];
        text = ''
          GH_TOKEN="$(
            gh-token generate \
              --app-id 5325279 \
              --installation-id 171592385 \
              --key /run/openclaw-secrets/github-app-key |
              jq -er '.token'
          )"
          export GH_TOKEN
          exec ${pkgs.gh}/bin/gh "$@"
        '';
      };
    in
    {
      # Use the same explicit identity on both sides of the bind mounts.
      users.groups.openclaw.gid = 61000;
      users.users.openclaw = {
        isSystemUser = true;
        uid = 61000;
        group = "openclaw";
        inherit home;
      };

      sops.secrets = {
        openclaw_gateway_password = secret "openclaw_gateway_password";
        openclaw_moltbook_key = secret "moltbook_api_key";
        openclaw_tavily_key = secret "tavily_api_key";
        telegram_openclawinator_bot = secret "telegram_openclawinator_bot";
        openclaw_github_app_key = secret "openclaw_github_app_key";
      };
      sops.templates."openclaw-litellm-key" = {
        owner = "openclaw";
        mode = "0400";
        content = config.sops.placeholder.litellm_master_key;
        restartUnits = [ "container@openclaw.service" ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/openclaw 0750 root openclaw -"
        "d ${home} 0700 openclaw openclaw -"
        "d ${home}/projects 0700 openclaw openclaw -"
        "d ${proposals} 0750 openclaw openclaw -"
      ];

      # Initialize once as the agent. Later deployments preserve its checkout.
      systemd.services.openclaw-checkout = {
        description = "Initialize the OpenClaw configuration checkout";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" "systemd-tmpfiles-setup.service" ];
        unitConfig.RequiresMountsFor = [ home ];
        path = [ pkgs.git pkgs.coreutils ];
        environment = {
          HOME = home;
          GIT_TERMINAL_PROMPT = "0";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "openclaw";
          Group = "openclaw";
          TimeoutStartSec = "5min";
        };
        script = ''
          set -euo pipefail
          checkout=${checkout}
          if [ -e "$checkout" ]; then
            test -d "$checkout/.git" || {
              echo "Existing checkout is not a Git clone: $checkout" >&2
              exit 1
            }
            exit 0
          fi
          temporary="$(mktemp -d "$checkout.init.XXXXXX")"
          trap 'rm -rf -- "$temporary"' EXIT
          git clone --branch main https://github.com/Yeshey/nixOS-Config.git "$temporary"
          git -C "$temporary" switch -c agent/openclaw-playground
          mv -T -- "$temporary" "$checkout"
        '';
      };

      containers.openclaw = {
        autoStart = true;
        ephemeral = true;
        # Keep localhost LiteLLM, Tailscale DNS, and the HTTPS proxy unchanged.
        privateNetwork = false;
        privateUsers = "no";
        specialArgs = { inherit inputs; };
        bindMounts = {
          "/home/openclaw" = { hostPath = home; isReadOnly = false; };
          "/home/openclaw/config" = { hostPath = proposals; isReadOnly = false; };
          "/host-config" = ro (toString inputs.self.outPath);
          "/run/openclaw-secrets/password" = ro config.sops.secrets.openclaw_gateway_password.path;
          "/run/openclaw-secrets/moltbook" = ro config.sops.secrets.openclaw_moltbook_key.path;
          "/run/openclaw-secrets/tavily" = ro config.sops.secrets.openclaw_tavily_key.path;
          "/run/openclaw-secrets/telegram" = ro config.sops.secrets.telegram_openclawinator_bot.path;
          "/run/openclaw-secrets/litellm" = ro config.sops.templates."openclaw-litellm-key".path;
          # Reuse Skyloft's existing SOPS identity. Never copy this into Git.
          "/run/openclaw-secrets/sops-ssh-key" = ro "/etc/ssh/ssh_host_ed25519_key";
          "/run/openclaw-secrets/github-app-key" = ro config.sops.secrets.openclaw_github_app_key.path;

          # Add project/data mounts here, for example:
          # "/projects/bolsa" = {
          #   hostPath = "/mnt/OneDrive/ISCTE/Projects/Bolsa";
          #   isReadOnly = false;
          # };
        };
        config = {
          imports = [
            inputs.home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
          ];
          sops = {
            defaultSopsFile = inputs.self.outPath + "/secrets/secrets.yaml";
            age = {
              keyFile = null;
              sshKeyPaths = [ "/run/openclaw-secrets/sops-ssh-key" ];
            };
          };
          nixpkgs.pkgs = pkgs.extend (_: _: {
            openclawRuntimePlugins.tavily = openclawPkgs.openclawRuntimePlugins.tavily;
          });
          system.stateVersion = hostConfig.system.stateVersion;
          environment.systemPackages = hostConfig.environment.systemPackages;
          # The network namespace is shared; the host owns firewall rules.
          networking.firewall.enable = false;
          # Preserve absolute workspace paths recorded by the previous deployment.
          # This is a guest-only alias, not a mount of Yeshey's host home.
          systemd.tmpfiles.rules = [ "L /home/yeshey - - - - /home/openclaw" ];
          users.groups.openclaw.gid = 61000;
          users.users.openclaw = {
            isNormalUser = true;
            uid = 61000;
            group = "openclaw";
            home = "/home/openclaw";
            linger = true;
          };
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.openclaw = {
              imports = [ inputs.self.modules.homeManager.openclaw ];
              home.username = "openclaw";
              home.homeDirectory = "/home/openclaw";
              home.stateVersion = "26.05";
              # Ensure agent subprocesses inherit the same host Nixpkgs source
              # used by login shells inside the container.
              systemd.user.services.openclaw-gateway.Service.Environment =
                lib.mkAfter [
                  "NIX_PATH=nixpkgs=${pkgs.path}"
                ];

              home.packages = [
                githubCli
                pkgs.git
                pkgs.jq
              ];

              programs.git = {
                enable = true;
                settings.credential."https://github.com" = {
                  helper = [
                    ""
                    "${githubCli}/bin/gh auth git-credential"
                  ];
                  useHttpPath = true;
                };
              };
            };
          };
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          # Point nix-shell and friends at the host's pinned Nixpkgs source
          # rather than a channel path that may not exist inside the guest.
          nix.nixPath = lib.mkForce [
            "nixpkgs=${pkgs.path}"
          ];
        };
      };

      systemd.services."container@openclaw" = {
        requires = [ "openclaw-checkout.service" ];
        after = [ "sops-nix.service" "openclaw-checkout.service" ];
        unitConfig.RequiresMountsFor = [ home proposals ];
      };
    };
}
