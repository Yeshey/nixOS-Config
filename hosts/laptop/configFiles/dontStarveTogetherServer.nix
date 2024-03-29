{ config, pkgs, user, location, dataStoragePath, lib, ... }:

{
  # Dont starve together server:
  virtualisation.oci-containers.containers = {
    dst-server = {
      image = "jamesits/dst-server:latest";
      volumes = [
        "${dataStoragePath}/PersonalFiles/Servers/dontstarvetogether/SurvivalServerMadeiraSummer2/DoNotStarveTogetherServer:/data:rw"
      ];
      environment = {
        DST_SERVER_ARCH = "amd64";
        DST_CLUSTER_TOKEN = "pds-g^KU_sJttONn9^jdHxLoAxJiKM4tH3lfWVuLxp3vq8mNTToe1OOGn0Fs8="; # "pds-g^KU_sJttONn9^Mk79OnW7xsITFY4PnG7ME+WS9Or86mhQ7+/kNzUGb30=";
      };
      extraOptions = [];
      ports = [
        "10999-11000:10999-11000/udp"
        "12346-12347:12346-12347/udp"
      ];
      autoStart = true;
    };
  };

  networking.firewall.allowedUDPPorts = [
    10999
    11000
    12346
    12347
    10998
  ];
}