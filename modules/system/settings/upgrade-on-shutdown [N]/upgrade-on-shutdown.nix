{
  flake.modules.nixos.upgrade-on-shutdown =
    { config, lib, pkgs, ... }:
    {
      # system-desktop imports system-cli, which imports upgrade.
      # Force-disable the weekly timer so only the shutdown service is active.
      system.autoUpgrade.enable = lib.mkForce false;

      systemd.services.nixos-upgrade-on-shutdown = {
        description = "NixOS System Upgrade on Shutdown";

        # The service starts silently at boot (ExecStart = true) and does the
        # real work in ExecStop, which runs as part of the shutdown sequence.
        # Reversed ordering during shutdown means After=network.target here
        # guarantees we still have network when ExecStop fires.
        after    = [ "network-online.target" ];
        wants    = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type             = "oneshot";
          RemainAfterExit  = true;

          # No-op at startup — just marks the unit as active.
          ExecStart = "${pkgs.coreutils}/bin/true";

          # Runs at shutdown, before network is torn down.
          ExecStop = pkgs.writeShellScript "nixos-upgrade-on-shutdown" ''
            set -euo pipefail
            echo "nixos-upgrade-on-shutdown: starting system upgrade before shutdown..."
            ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch \
              --flake "github:yeshey/nixos-config#${config.networking.hostName}" \
              --update-input nixpkgs \
              --no-write-lock-file \
              -L \
              && echo "nixos-upgrade-on-shutdown: upgrade complete." \
              || echo "nixos-upgrade-on-shutdown: upgrade failed (shutdown continues)."
          '';

          # Give the upgrade as much time as it needs; never time out.
          TimeoutStopSec = "infinity";
        };
      };
    };
}