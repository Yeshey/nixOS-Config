{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hyprland;
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
in
{
  imports = [ inputs.hyprland.nixosModules.default ];

  options.mySystem.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    programs.hyprland = {
      enable = lib.mkOverride 1010 true;
      xwayland.enable = lib.mkOverride 1010 true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    xdg.portal = {
      enable = true;
      wlr.enable = false;
      xdgOpenUsePortal = false;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    # to remember internet, idk if I need all this
    networking.networkmanager.enable = lib.mkOverride 1010 true;
    services.gnome.gnome-keyring.enable = lib.mkOverride 1010 true;
    programs.seahorse.enable = lib.mkIf (!config.mySystem.plasma.enable) true; # enable the graphical frontend
    environment.systemPackages = [ pkgs.libsecret ]; # libsecret api needed
    security.pam.services.gdm.enableGnomeKeyring = lib.mkOverride 1010 true; # load gnome-keyring at startup
    environment.variables.XDG_RUNTIME_DIR = lib.mkOverride 1010 "/run/user/$UID"; # set the runtime directory

    # displayManager
    services.greetd = {
      enable = lib.mkOverride 1010 true;
      settings = {
        default_session = {
          command = "${tuigreet} --time --remember --cmd Hyprland";
          user = "greeter";
        };
      };
    };
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal"; # Without this errors will spam on screen
      # Without these bootlogs will spam on screen
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    # if nvidia
    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = lib.mkIf config.mySystem.hardware.nvidia.enable "1";
    };

    boot.kernelParams = lib.mkIf config.mySystem.hardware.nvidia.enable [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    hardware.nvidia.powerManagement.enable = lib.mkIf config.mySystem.hardware.nvidia.enable true;
    # Making sure to use the proprietary drivers until the issue above is fixed upstream
    hardware.nvidia.open = lib.mkIf config.mySystem.hardware.nvidia.enable false;

    # Special config to load the latest (535 or 550) driver for the support of the 4070 SUPER
    hardware.nvidia.package =
      let
        rcu_patch = pkgs.fetchpatch {
          url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
          hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
        };
      in
      config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "535.154.05";
        sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
        sha256_aarch64 = "sha256-G0/GiObf/BZMkzzET8HQjdIcvCSqB1uhsinro2HLK9k=";
        openSha256 = "sha256-wvRdHguGLxS0mR06P5Qi++pDJBCF8pJ8hr4T8O6TJIo=";
        settingsSha256 = "sha256-9wqoDEWY4I7weWW05F4igj1Gj9wjHsREFMztfEmqm10=";
        persistencedSha256 = "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";

        #version = "550.40.07";
        #sha256_64bit = "sha256-KYk2xye37v7ZW7h+uNJM/u8fNf7KyGTZjiaU03dJpK0=";
        #sha256_aarch64 = "sha256-AV7KgRXYaQGBFl7zuRcfnTGr8rS5n13nGUIe3mJTXb4=";
        #openSha256 = "sha256-mRUTEWVsbjq+psVe+kAT6MjyZuLkG2yRDxCMvDJRL1I=";
        #settingsSha256 = "sha256-c30AQa4g4a1EHmaEu1yc05oqY01y+IusbBuq+P6rMCs=";
        #persistencedSha256 = "sha256-11tLSY8uUIl4X/roNnxf5yS2PQvHvoNjnd2CB67e870=";

        patches = [ rcu_patch ];
      };

    hardware.opengl =
      { }
      // lib.mkIf config.mySystem.hardware.nvidia.enable {
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          intel-media-driver
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          nvidia-vaapi-driver
          intel-media-driver
        ];
      };
  };
}
