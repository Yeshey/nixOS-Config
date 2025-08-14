{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.plasma;
in
{
  options.mySystem.plasma = {
    enable = lib.mkEnableOption "plasma";
    x11 = lib.mkEnableOption "x11";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    # KDE Plasma
    #programs.qt5ct.enable = true;
/*
    qt = {
      enable = true;
      platformTheme = "";
      style = "adwait";
    }; */
/*
    qt = {
      enable = true;
      platformTheme = "qt5ct";
      style = "breeze";
    };*/
    /*
    gtk = {
      #enable = true;
      theme = {
        name = "Breeze-Dark";
        package = pkgs.libsForQt5.breeze-gtk;
      };
    };*/

    # For hotspot to connect (in KDE plasma)
    # https://github.com/NixOS/nixpkgs/issues/263359
    networking.firewall.allowedUDPPorts = [ 67 68 53 
    ];
    networking.firewall.allowedTCPPorts = [ 67 68 53 
    ];

    services = {
      desktopManager.plasma6.enable = true;

      displayManager.sddm.enable = true;

      displayManager.sddm.wayland.enable = true;

      xserver = {
        enable = true;

        #xkb = {
        #  layout = "us";
        #  variant = "";
        #};
      };
    };

    environment.systemPackages = with pkgs;
      [
        kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
        kdePackages.kcalc # Calculator
        kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
        kdePackages.kcolorchooser # A small utility to select a color
        kdePackages.kolourpaint # Easy-to-use paint program
        kdePackages.ksystemlog # KDE SystemLog Application
        kdePackages.sddm-kcm # Configuration module for SDDM
        kdiff3 # Compares and merges 2 or 3 files or directories
        kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
        kdePackages.partitionmanager # Optional Manage the disk devices, partitions and file systems on your computer
        hardinfo2 # System information and benchmarks for Linux systems
        haruna # Open source video player built with Qt/QML and libmpv
        wayland-utils # Wayland utilities
        wl-clipboard # Command-line copy/paste utilities for Wayland

        kdePackages.sddm-kcm # for sddm configuration in settings
        unrar # also to extract .rar with ark in KDE # unrar x Lab5.rar
        ocs-url # to install plasma widgets # do installed things not work?
      ];
  };
}
