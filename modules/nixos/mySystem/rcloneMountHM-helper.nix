{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.snap;
in
{
  options.mySystem.rcloneMountHM-helper = with lib; {
    enable = mkEnableOption "rcloneMountHM-helper to restart on network changes";
  };

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # This is needed for rclone mount by user. Maybe make a file turn it into an option idk.
    programs.fuse.enable = true;
    programs.fuse.userAllowOther = true;

    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "rclone-user-restart-hook" ''
          #!/bin/sh
          
          ACTION="$2"
          USER="yeshey"  # Your username
          
          # Logging
          log() { logger -t "rclone-user-dispatcher" "$1"; }
          
          # Log that the script was called
          log "Script called with ACTION=$ACTION"
          
          # Sleep check - don't restart during suspend/hibernate
          if systemctl is-active --quiet sleep.target || \
            systemctl is-active --quiet suspend.target || \
            systemctl is-active --quiet hibernate.target || \
            systemctl is-active --quiet suspend-then-hibernate.target || \
            systemctl is-active --quiet hybrid-sleep.target; then
            log "System is sleeping/hibernating. Ignoring event $ACTION."
            exit 0
          fi
          
          # Action handler
          case "$ACTION" in
            up|vpn-up|vpn-down|dhcp4-change|dhcp6-change)
              log "Network UP ($ACTION). Restarting user rclone mount for $USER..."
              
              # Get the user's runtime directory
              USER_ID=$(id -u "$USER")
              export XDG_RUNTIME_DIR="/run/user/$USER_ID"
              export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
              
              # Restart the user service using sudo
              ${pkgs.sudo}/bin/sudo -u "$USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
                ${pkgs.systemd}/bin/systemctl --user restart --no-block rclone-mount.service && \
                log "Successfully restarted rclone-mount for user $USER" || \
                log "Failed to restart rclone-mount for user $USER"
              ;;
            *)
              log "Ignoring action: $ACTION"
              ;;
          esac
        '';
      }
    ];
  };
}
