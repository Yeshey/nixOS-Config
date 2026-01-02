{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.gnome;
in
{
  options.mySystem.gnome = {
    enable = lib.mkEnableOption "gnome";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # Get specific patches
    # nixpkgs.overlays = [
    #   (final: prev: {
    #     mutter = prev.mutter.overrideAttrs (oldAttrs: {
    #       patches = (oldAttrs.patches or []) ++ [
    #         (final.fetchpatch {
    #           url = "https://gitlab.gnome.org/GNOME/mutter/-/commit/d71bab8d4d3ef0e35a0afa627825cc35892ee1cf.patch";
    #           sha256 = "sha256-F5ZJezzgfF7ci6B/W0g7FvDRvZWWWCy95Xf/dCiBz60=";
    #         })
    #       ];
    #     });
    #   })
    # ];

    # External monitors (I think you need this for the brightness to work, but it might be added to nixOS gnome module if it really works so I might just remove it in the future)
    # Also it doesn't currently work with nvidia apparently: https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/4763#note_2610835
    # hardware.i2c.enable = true;
    # services.ddccontrol.enable = true;
    # boot.kernelModules = ["i2c-dev" "ddcci_backlight"];
    # boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];

    environment = {
      systemPackages = with pkgs; [ firefox ];
      gnome.excludePackages = with pkgs; [
        gedit # text editor
        epiphany # web browser
        geary # email reader
        #evince # document viewer
        totem # video player
        gnome-connections
        gnome-contacts
        # gnome-maps
        gnome-music
      ];
    };

    programs.ssh.startAgent = lib.mkForce false; # because gnome now has their own ssh agent? gcr-ssh-agent

    # with this you can use Super + . to get in emoji annotation mode. The type the name of your emoji and space to select the correct one
    i18n.inputMethod = {
      enable = true;
      type = "ibus";
    };

    # for audio and video properties in nautilus interface https://github.com/NixOS/nixpkgs/issues/53631
    environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-plugins-ugly
      pkgs.gst_all_1.gst-plugins-base
    ];

    services = {
      # layout = "pt";
      displayManager.gdm = {
        enable = lib.mkOverride 1010 true;
        # autoSuspend = false;
        settings = {
          greeter.IncludeAll = true;
        };
      };
      desktopManager = {
        gnome.enable = true;
      };
      udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    security.rtkit.enable = true;
  };
}
