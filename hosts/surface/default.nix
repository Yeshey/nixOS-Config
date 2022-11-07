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

{ config, pkgs, user, location, ... }:

{
  imports =                                     # For now, if applying to other system, swap files
    [(import ./hardware-configuration.nix)];    # Current system hardware config @ /etc/nixos/hardware-configuration.nix

  # swap in ext4:
  swapDevices = [ 
    {
      device = "/var/lib/swapfile";
      priority = 100;
      size = 5*1024;
    }
    {
      device = "/mnt/btrfsMicroSD/swapfile";
      priority = 0;
      size = 7*1024;
    } 
  ];

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
  services.thermald = {
    enable = true;
    configFile = ./configFiles/thermal-conf.xml; #(https://github.com/linux-surface/linux-surface/blob/master/contrib/thermald/thermal-conf.xml)
  };

/*
# https://github.com/linux-surface/iptsd
# https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/applications/misc/iptsd/default.nix
  nixpkgs.overlays = [ # This overlay will pull the latest version of iptsd
    (self: super:
      {
        iptsd = super.iptsd.overrideAttrs (old: {
          src = super.fetchFromGitHub {
            owner = "linux-surface";
            repo = "iptsd";
            rev = "87698d6bcfe03bfe901ed2714c4648c99e645df5";
            sha256 = "sha256-YlfpHDGDpMZRbwX+SSX8owOsngGsaC+l6kwMESJMlWc=";
          };
            mesonFlags = [
            "-Dservice_manager=systemd"
            "-Dsample_config=false"
          ];
            
            # https://www.reddit.com/r/NixOS/comments/ygssgm/make_simple_overlay_properly/
            nativeBuildInputs = old.nativeBuildInputs ++ [ 
                self.gcc
                self.cmake 
                self.cli11 
                self.fmt
                self.spdlog
                self.microsoft_gsl
                self.hidrd
                self.SDL2
                self.cairomm
              ];
                # Original installs udev rules and service config into global paths
              prePatch = ''
                echo FUCKKKKKKKKKKKKKKKKKKKKKKKKKKKK
                ls
                sed -i 's/b_lto=true/b_lto=false/g' meson.build
                cat meson.build

              '';
        });
      })
  ];
  */

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    touchegg
    # iptsd
  ];

}
