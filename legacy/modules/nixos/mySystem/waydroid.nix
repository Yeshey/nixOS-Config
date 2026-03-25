{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.waydroid;
in
{
  options.mySystem.waydroid = {
    enable = lib.mkEnableOption "waydroid";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable)  {
    virtualisation.waydroid.enable = true;

    environment.systemPackages = with pkgs; [
      # nur.repos.ataraxiasjel.waydroid-script # https://www.reddit.com/r/NixOS/comments/15k2jxc/need_help_with_activating_libhoudini_for_waydroid/
      unstable.waydroid-helper
      # wl-clipboard # to make clipboard work
    ];

    systemd = {
      packages = [ pkgs.waydroid-helper ];
      # uncomment when you're on 25.11 I guess
      #services.waydroid-mount.wantedBy = [ "multi‑user.target" ];;
    };
    
  };
}
