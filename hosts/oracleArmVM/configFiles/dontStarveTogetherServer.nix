{ config, pkgs, user, location, dataStoragePath, lib, ... }:

{
  /*
  # Dont starve together server:
  virtualisation.oci-containers.containers = {
    dst-server = {
      image = "docker.io/jamesits/dst-server:latest";
      volumes = [
        "${dataStoragePath}/Servers/dontstarve/serv-Survival1/DoNotStarveTogetherServer:/data:rw"
      ];
      environment = {
        DST_SERVER_ARCH = "amd64";
        DST_CLUSTER_TOKEN = "pds-g^KU_sJttONn9^Mk79OnW7xsITFY4PnG7ME+WS9Or86mhQ7+/kNzUGb30=";
      };
      extraOptions = [ "--platform=linux/amd64" ];
      ports = [
        "10999-11000:10999-11000/udp"
        "12346-12347:12346-12347/udp"
      ];
      autoStart = true;
    };
  };
  */

  #virtualisation.docker.enable = true;
  #virtualisation.docker.enableOnBoot = true; # Big WTF
  #virtualisation.docker.storageDriver = "btrfs";

  #environment.systemPackages = with pkgs; [
  # box64
  #];
  # boot.binfmt.emulatedSystems = [ "x86_64-linux" ];  
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ]; # this breaks with this error: <---------
  /*
restarting the following units: nix-daemon.service
open3: exec of /nix/store/j1c20f57gn0y9y9kr61dlgjll2hlhbnp-system-path/bin/busctl --json=short call org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager ListUnitsByPatterns asas 0 0 failed: Too many levels of symbolic links at /nix/store/82a9ld0177rnnsfklwlf27bvk733vyln-perl-5.36.0/lib/perl5/5.36.0/IPC/Cmd.pm line 1531.
warning: error(s) occurred while switching to the new configuration
/nix/store/y0yp1wyhlkgd8vy638pajania07ycmxm-nixos-rebuild/bin/nixos-rebuild: line 384: /nix/store/sdfpzhcksqwsfya89ldci3yhvw6sywg9-coreutils-9.1/bin/rm: Too many levels of symbolic links
  */
  networking.firewall.allowedUDPPorts = [
    10999
    11000
    12346
    12347
    10998
  ];
}