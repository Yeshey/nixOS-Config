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

{ config, pkgs, user, ... }:

{
  imports =                                     # For now, if applying to other system, swap files
    [(import ./hardware-configuration.nix)];    # Current system hardware config @ /etc/nixos/hardware-configuration.nix

  nixpkgs.overlays = [                          # This overlay will pull the latest version of Discord
    (self: super: {
      discord = super.discord.overrideAttrs (
        _: { src = builtins.fetchTarball {
          url = "https://discord.com/api/download?platform=linux&format=tar.gz"; 
          sha256 = "0qaczvp79b4gzzafgc5ynp6h4nd2ppvndmj6pcs1zys3c0hrabpv";
        };}
      );
    })
  ];

  #https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2021.3.1.16/android-studio-2021.3.1.16-linux.tar.gz

  environment.systemPackages = with pkgs; [
    # tmp
    virt-manager # for android studio (installed through flatpak for latest version)

    # Games
    osu-lazer
  ];
  programs.adb.enable = true;

}
