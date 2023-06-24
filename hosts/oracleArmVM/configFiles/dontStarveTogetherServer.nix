{ config, pkgs, user, location, dataStoragePath, lib, ... }:

{
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
  environment.systemPackages = with pkgs; [
    qemu
  ];  
  #boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  networking.firewall.allowedUDPPorts = [
    10999
    11000
    12346
    12347
    10998
  ];
}