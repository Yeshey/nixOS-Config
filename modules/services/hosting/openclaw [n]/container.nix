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

      containers.openclaw = {
        autoStart = true;
        ephemeral = true;
        # Keep localhost LiteLLM, Tailscale DNS, and the HTTPS proxy unchanged.
        privateNetwork = false;
        privateUsers = "no";
        bindMounts = {
          "/home/openclaw" = { hostPath = home; isReadOnly = false; };
          "/home/openclaw/config" = { hostPath = proposals; isReadOnly = false; };
          "/host-config" = ro (toString inputs.self.outPath);
          "/run/openclaw-secrets/password" = ro config.sops.secrets.openclaw_gateway_password.path;
          "/run/openclaw-secrets/moltbook" = ro config.sops.secrets.openclaw_moltbook_key.path;
          "/run/openclaw-secrets/tavily" = ro config.sops.secrets.openclaw_tavily_key.path;
          "/run/openclaw-secrets/telegram" = ro config.sops.secrets.telegram_openclawinator_bot.path;
          "/run/openclaw-secrets/litellm" = ro config.sops.templates."openclaw-litellm-key".path;

          # Add project/data mounts here, for example:
          # "/projects/bolsa" = {
          #   hostPath = "/mnt/OneDrive/ISCTE/Projects/Bolsa";
          #   isReadOnly = false;
          # };
        };
        config = {
          imports = [ inputs.home-manager.nixosModules.home-manager ];
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
            };
          };
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
        };
      };
      systemd.services."container@openclaw" = {
        after = [ "sops-nix.service" ];
        unitConfig.RequiresMountsFor = [ home proposals ];
      };
    };
}