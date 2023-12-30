{ config, pkgs, user, location, lib, dataStoragePath, ... }:

let
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # so "~/Documents" becomes "Documents"
in
{
  # Connect to codium-server: (ssh -L 9090:localhost:3000 -t yeshey@143.47.53.175 "sleep 90" &) && xdg-open http://localhost:9090
  # In powershell: ssh -L 9090:localhost:3000 -t yeshey@143.47.53.175 "sleep 90" # http://localhost:9090
  # http://130.61.219.132 - Nextcloud # root / test123
  # http://130.61.219.132:7843 - nginx

  imports = [
    (import ./hardware-configuration.nix)

    #(import ./configFiles/dontStarveTogetherServer.nix)
    (import ./configFiles/nextcloud.nix)
    (import ./configFiles/minecraft.nix)
    (import ./configFiles/openvscode-server.nix)
    (import ./configFiles/ngix-server.nix)
    (import ./configFiles/mineclone.nix)
    (import ./configFiles/kubo.nix)
  ];
  
  #time.timeZone = "Europe/Berlin";
  time.timeZone = "Europe/Madrid";

  # swap in btrfs:
  # ...

  nixpkgs.config = {
  	allowUnsupportedSystem = true;
#    allowUnfree = true;
    permittedInsecurePackages = [ # for package openvscode-server
      "nodejs-16.20.2"
    ];
  };

  #    ____             _               ____      ___                                 
  #   / __/__ _____  __(_)______ ___   / __/___  / _ \_______  ___ ________ ___ _  ___
  #  _\ \/ -_) __/ |/ / / __/ -_|_-<   > _/_ _/ / ___/ __/ _ \/ _ `/ __/ _ `/  ' \(_-<
  # /___/\__/_/  |___/_/\__/\__/___/  |_____/  /_/  /_/  \___/\_, /_/  \_,_/_/_/_/___/
  #                                                          /___/                                                     

  # use x86_64 steam and allow unfree license
  # https://discourse.nixos.org/t/how-to-install-steam-x86-64-on-a-pinephone-aarch64/19297/4
  # You need to copy the relevant things manualy
  /*
  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  nixpkgs.overlays = [(self: super: let
    x86pkgs = import pkgs.path { system = "x86_64-linux";
      config = {
        allowUnfree = true;
        allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "steam"
          "steam-original"
          "steam-runtime"
        ];
      };
    };
  in {
    inherit (x86pkgs) steam steam-run;
  })];
  # allow build for x86_64-linux architecture through emulation
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  environment.systemPackages = with pkgs; [
    steam steam-run
  ];
  */


  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  networking.firewall.allowedTCPPorts = [ 3389 ];

  environment.systemPackages = with pkgs; [
    #turbovnc
  ];          

  # For Syncthing, create folders (not sure if necessary)
  # Access syncthing with (ssh -L 9091:localhost:8384 -t yeshey@143.47.53.175 "sleep 90" &) && xdg-open http://localhost:9091
  # https://discourse.nixos.org/t/is-it-possible-to-declare-a-directory-creation-in-the-nixos-configuration/27846/5
  systemd.tmpfiles.rules = [
        "d ${shortenedPath}/PersonalFiles/2023 0770 ${user} users -"
        "d ${shortenedPath}/PersonalFiles/2022 0770 ${user} users -"
        "d ${shortenedPath}/PersonalFiles/Servers 0770 ${user} users -"
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
