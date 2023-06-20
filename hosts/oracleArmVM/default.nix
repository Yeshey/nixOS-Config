{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
  imports = [                                     # For now, if applying to other system, swap files
    (import ./configFiles/nextcloud.nix)
    (import ./hardware-configuration.nix)
  ];    # Current system hardware config @ /etc/nixos/hardware-configuration.nix
  
  time.timeZone = "Europe/Berlin";

  # swap in btrfs:
  # ...

  nixpkgs.config = {
  	allowUnsupportedSystem = true;
  };

  #     ___            __ 
  #    / _ )___  ___  / /_
  #   / _  / _ \/ _ \/ __/
  #  /____/\___/\___/\__/  

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    
  ];

 #    ____             _               ____      ___                                 
  #   / __/__ _____  __(_)______ ___   / __/___  / _ \_______  ___ ________ ___ _  ___
  #  _\ \/ -_) __/ |/ / / __/ -_|_-<   > _/_ _/ / ___/ __/ _ \/ _ `/ __/ _ `/  ' \(_-<
  # /___/\__/_/  |___/_/\__/\__/___/  |_____/  /_/  /_/  \___/\_, /_/  \_,_/_/_/_/___/
  #                                                          /___/                                                               

}
