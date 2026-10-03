{ inputs, ... }:
{
  flake.modules.nixos.pithagoras =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      repoDir = "/var/lib/pithagoras/workspaces/bolsa"; # production checkout, same dir the container sees as /workspaces/bolsa
      dataDir = "/mnt/OneDrive/ISCTE/Projects/Bolsa";

      # false: the daily job runs whatever is checked out (you `git pull` by hand).
      # true: it first does `git fetch` + `git reset --hard origin/main`. Needs git credentials for Forgejo on the
      # host, which are not set up yet, so leave this false until agents start merging PRs.
      syncMain = false;

      # Forgejo runner: stays completely inert while this is empty (see registration steps).
      runnerUuid = "";
      runnerEnabled = runnerUuid != "";
      forgejoHost = "skyloft.tailb6874b.ts.net";
      runnerNet = "forgejo-runner";
      runnerBridge = "br-forgejo";
      docker = "${config.virtualisation.docker.package}/bin/docker";
    in
    {
      # `imports` MUST be at the top level of the module's return value.
      # It does not work inside `lib.mkIf` or `lib.mkMerge` branches,
      # because the module loader only processes `imports` before
      # evaluating any option definitions.
      imports = [
        "${inputs.nixpkgs-unstable}/nixos/modules/services/continuous-integration/forgejo-runner.nix"
      ];

      # ---------------------------------------------------------------
      # Daily job: refresh prices, run every strategy, rebuild dashboard.
      # Plain Python, no agents, no LLM calls, no containers.
      # ---------------------------------------------------------------
      systemd.services.bolsa-daily = {
        description = "Bolsa daily: prices, shadow scoring, dashboard";
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "remote-fs.target"
        ];
        path = with pkgs; [
          nix
          git
          bash
          coreutils
          gnugrep
          gnused
        ];
        environment = {
          HOME = "/var/lib/bolsa";
          BOLSA_DATA_DIR = dataDir;
          NIX_CONFIG = "experimental-features = nix-command flakes";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        serviceConfig = {
          Type = "oneshot";
          WorkingDirectory = repoDir; # harness.daily reads ./.env from here
          StateDirectory = "bolsa";
          TimeoutStartSec = "30min";
        };
        script = ''
          ${lib.optionalString syncMain ''
            git fetch -q origin
            git reset -q --hard origin/main
          ''}
          exec ${pkgs.bash}/bin/bash scripts/run python -m harness.daily
        '';
      };

      # US close is 20:00-21:00 Lisbon time all year; 22:30 leaves margin.
      # Persistent: if the machine was off at 22:30, run once when it comes back (the job is idempotent per day).
      systemd.timers.bolsa-daily = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Mon..Fri 22:30 Europe/Lisbon";
          Persistent = true;
          RandomizedDelaySec = "2m";
        };
      };

      # ---------------------------------------------------------------
      # Forgejo runner (for the PR reviewer later). Inert until runnerUuid is set.
      # ---------------------------------------------------------------

      # The sops secret is defined unconditionally so it always exists in the
      # option tree. Otherwise, when runnerEnabled is false, the reference to
      # `config.sops.secrets."forgejo_runner_secret".path` inside the runner
      # block below would fail with `attribute 'forgejo_runner_secret' missing`.
      #
      # Consequence: sops-nix will still require the key to be present in the
      # encrypted file at activation time, even when the runner is disabled.
      # That is fine — the value is simply unused until you enable the runner.
      sops.secrets."forgejo_runner_secret" = { };

      services.forgejo-runner.instances.bolsa = lib.mkIf runnerEnabled {
        enable = true;
        settings = {
          runner = {
            capacity = 1;
            timeout = "30m";
            labels = [ "docker:docker://node:22-bookworm" ];
          };
          server.connections.default = {
            url = "http://${forgejoHost}:3000/";
            uuid = runnerUuid;
          };
          container = {
            network = runnerNet;
            options = "--add-host=${forgejoHost}:host-gateway --security-opt=no-new-privileges --memory=4g --pids-limit=512";
            docker_host = "-"; # do NOT mount the Docker socket into jobs
            privileged = false;
            valid_volumes = [ ]; # no host bind mounts: jobs cannot see the Bolsa data folder
          };
        };
        secrets.server.connections.default.token_url =
          config.sops.secrets."forgejo_runner_secret".path;
      };

      # Dedicated bridge with a fixed name so the firewall can open Forgejo's port for jobs only.
      systemd.services.docker-network-forgejo-runner = lib.mkIf runnerEnabled {
        description = "Docker network for Forgejo runner jobs";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        before = [ "forgejo-runner-bolsa.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${docker} network inspect ${runnerNet} >/dev/null 2>&1 || \
            ${docker} network create --opt com.docker.network.bridge.name=${runnerBridge} ${runnerNet}
        '';
      };

      networking.firewall.interfaces.${runnerBridge}.allowedTCPPorts =
        lib.mkIf runnerEnabled [ 3000 ];
    };
}