{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.agenix;
  inherit (pkgs.stdenv.hostPlatform) system; # for agenix pkg
in
{
  imports = [
    inputs.agenix.nixosModules.default
    ./sshKeys.nix
  ];

  options.mySystem.agenix = with lib; {
    enable = mkEnableOption "agenix";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    environment.systemPackages = [ inputs.agenix.packages.${system}.agenix ]; # adds agenix

    # to provide key for agenix
    services.openssh = {
      enable = true;
      # openFirewall = false;
    };

    /*
    systemd.services."test" = {
      script = ''
        cat ${config.age.secrets.my_identity.path} > /home/yeshey/Downloads/test.txt
      '';
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    }; */

    age = {
      secrets = {

        my_identity = {
          file = ./../../../../secrets/my_identity.age;
          #mode = "0440";
          #group = config.users.groups.keys.name;
        };

        free_games = {
          file = ./../../../../secrets/free_games.age;
          #mode = "0440";
          #group = config.users.groups.keys.name;
        };

      };
    };

  };
}
