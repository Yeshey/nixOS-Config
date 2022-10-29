#
#  Specific system configuration settings for desktop
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ ./desktop
#   │        ├─ default.nix *
#   │        └─ hardware-configuration.nix
#   └─ ./modules
#       └─ ./desktop
#           └─ ./qemu
#               └─ default.nix
#
# Surface is underpowered, use this command in the more powerfull machine to build:
# sudo nixos-rebuild --flake .#surface --target-host root@192.168.1.115 --build-host localhost switch
#
# Or use this one in the surface:
# sudo nixos-rebuild --flake .#surface --build-host root@192.168.1.102 switch

{ config, pkgs, user, ... }:

{
  imports =                                     # For now, if applying to other system, swap files
    [(import ./hardware-configuration.nix)];    # Current system hardware config @ /etc/nixos/hardware-configuration.nix

  # swap in ext4:
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 17*1024;
  } ];

  #     ___            __ 
  #    / _ )___  ___  / /_
  #   / _  / _ \/ _ \/ __/
  #  /____/\___/\___/\__/  

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # GNOME Desktop (uses wayland)
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    # Make Surface Touchpad Work:
    desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.peripherals.touchpad]
      click-method='default'
    '';
  };

  # A multi-touch gesture recognizer
  services.touchegg.enable = true;
  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    touchegg
  ];

}
