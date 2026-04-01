{
  inputs,
  ...
}:
{
  flake.modules.nixos.plasma-full-tier = 
    { pkgs, ... }: 
    {
      imports = with inputs.self.modules.nixos; [
        plasma-minimal
      ];

      # For hotspot to connect (in KDE plasma)
      # https://github.com/NixOS/nixpkgs/issues/263359
      networking.firewall.allowedUDPPorts = [ 67 68 53 ];
      networking.firewall.allowedTCPPorts = [ 67 68 53 ];

      services = {
        xserver = {
          enable = true;
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

  flake.modules.homeManager.plasma-full-tier = {
    imports = with inputs.self.modules.homeManager; [
      plasma-minimal-tier
    ];
  };
}