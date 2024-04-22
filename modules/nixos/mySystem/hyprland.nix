{ inputs, config, lib, pkgs, ... }:

let
  cfg = config.mySystem.hyprland;
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
in
{
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  options.mySystem.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {

    #programs.hyprland.enable = true;
    # programs.hyprland.nvidiaPatches=true;
    #programs.hyprland.xwayland.enable=true;

    programs.hyprland = {
     enable = true;
     xwayland.enable = true;
     package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    # if nvidia
    #boot.kernelParams = lib.mkIf config.mySystem.hardware.nvidia.enable [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    #hardware.nvidia.powerManagement.enable = lib.mkIf config.mySystem.hardware.nvidia.enable true;
    # Making sure to use the proprietary drivers until the issue above is fixed upstream
    #hardware.nvidia.open = lib.mkIf config.mySystem.hardware.nvidia.enable false;

    boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    hardware.nvidia.powerManagement.enable = true;
    # Making sure to use the proprietary drivers until the issue above is fixed upstream
    hardware.nvidia.open = false;

    hardware.opengl = {
      extraPackages = with pkgs; [nvidia-vaapi-driver intel-media-driver];
      extraPackages32 = with pkgs.pkgsi686Linux; [nvidia-vaapi-driver intel-media-driver];
    };

    # to remember internet, idk if I need all this
    networking.networkmanager.enable = true;
    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true; # enable the graphical frontend
    environment.systemPackages = [ pkgs.libsecret ]; # libsecret api needed
    security.pam.services.gdm.enableGnomeKeyring = true; # load gnome-keyring at startup
    environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID"; # set the runtime directory

    # displayManager
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${tuigreet} --time --remember --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    # this is a life saver.
    # literally no documentation about this anywhere.
    # might be good to write about this...
    # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
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

  };
}
