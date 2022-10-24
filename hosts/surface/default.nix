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

  environment.systemPackages = with pkgs; [

  ];

}
