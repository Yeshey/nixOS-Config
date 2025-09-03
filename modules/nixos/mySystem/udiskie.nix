{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.udiskie;
in
{
  options.mySystem.udiskie = {
    enable = lib.mkEnableOption "udiskie";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable)  {
    services.udisks2.enable = true;

    # Ensure required packages are available
    environment.systemPackages = with pkgs; [
      udiskie
      udisks2
      ntfs3g  # For NTFS support
    ];

    # Enable udiskie as a user service that starts with the desktop session
    systemd.user.services.udiskie = {
      wantedBy = [ "graphical-session-pre.target" ];  # after panel
      after    = [ "graphical-session-pre.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --notify --tray";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    # Remove your old static mount configurations
    # Comment out or remove the fileSystems entries you showed

    # For your specialisation that disables mounts, replace those entries with:
    # systemd.user.services.udiskie.enable = lib.mkForce false;
    # services.udisks2.enable = lib.mkForce false;
  };
}
