{ ... }:
{
  flake.modules.nixos.pithagoras =
    { pkgs, config, ... }:
    let
      repoDir = "/var/lib/pithagoras/workspaces/bolsa"; # live checkout, only ever holds merged main
    in
    {
      # Only the judge token. Reviewer token stays out of this service.
      sops.secrets."forgejo_judge_token" = { };
      sops.templates."bolsa-merge.env".content = ''
        FORGEJO_JUDGE_TOKEN=${config.sops.placeholder."forgejo_judge_token"}
      '';

      # Free job: merges PRs the reviewer approved. Exits fast if nothing to do.
      systemd.services.bolsa-merge = {
        description = "Bolsa: merge approved PRs";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
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
          NIX_CONFIG = "experimental-features = nix-command flakes";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        serviceConfig = {
          Type = "oneshot";
          WorkingDirectory = repoDir;
          StateDirectory = "bolsa";
          EnvironmentFile = config.sops.templates."bolsa-merge.env".path;
          TimeoutStartSec = "5min";
        };
        script = ''
          exec ${pkgs.python312}/bin/python scripts/merge_approved.py
        '';
      };

      systemd.timers.bolsa-merge = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/10";
          RandomizedDelaySec = "30s";
        };
      };
    };
}