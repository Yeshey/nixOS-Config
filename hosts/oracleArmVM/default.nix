{ config, pkgs, user, location, lib, dataStoragePath, ... }:

let
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # so "~/Documents" becomes "Documents"
in
{
  # Connect to codium-server: (ssh -L 9090:localhost:3000 -t yeshey@130.61.219.132 "sleep 90" &) && xdg-open http://localhost:9090
  # http://130.61.219.132 - Nextcloud # root / test123
  # http://130.61.219.132:7843 - nginx

  imports = [
    (import ./hardware-configuration.nix)

    (import ./configFiles/dontStarveTogetherServer.nix)
    (import ./configFiles/nextcloud.nix)
    (import ./configFiles/minecraft.nix)
    (import ./configFiles/openvscode-server.nix)
    (import ./configFiles/ngix-server.nix)
    # (import ./configFiles/kubo.nix)
  ];
  
  #time.timeZone = "Europe/Berlin";
  time.timeZone = "Europe/Madrid";

  # swap in btrfs:
  # ...

  nixpkgs.config = {
  	allowUnsupportedSystem = true;
     permittedInsecurePackages = [ # for package openvscode-server
                    "nodejs-16.20.2"
                  ];
  };

  #    ____             _               ____      ___                                 
  #   / __/__ _____  __(_)______ ___   / __/___  / _ \_______  ___ ________ ___ _  ___
  #  _\ \/ -_) __/ |/ / / __/ -_|_-<   > _/_ _/ / ___/ __/ _ \/ _ `/ __/ _ `/  ' \(_-<
  # /___/\__/_/  |___/_/\__/\__/___/  |_____/  /_/  /_/  \___/\_, /_/  \_,_/_/_/_/___/
  #                                                          /___/                                                     

  environment.systemPackages = with pkgs; [

  ];          

  # For Syncthing
  # Access syncthing with (ssh -L 9091:localhost:8384 -t yeshey@143.47.53.175 "sleep 90" &) && xdg-open http://localhost:9091
  systemd.tmpfiles.rules = [
        "d ${shortenedPath}/PersonalFiles/2023 0770 ${user} users -"
        "d ${shortenedPath}/PersonalFiles/2022 0770 ${user} users -"
        "d ${shortenedPath}/PersonalFiles/Timeless/Syncthing/PhoneCamera 0770 ${user} users -"
        "d ${shortenedPath}/PersonalFiles/Timeless/Syncthing/Allsync/ 0770 ${user} users -"
        "d ${shortenedPath}/PersonalFiles/Timeless/Music/ 0770 ${user} users -"
  ];

  #     ___            __ 
  #    / _ )___  ___  / /_
  #   / _  / _ \/ _ \/ __/
  #  /____/\___/\___/\__/  

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

}
