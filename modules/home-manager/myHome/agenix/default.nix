{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.myHome.agenix;
  inherit (pkgs.stdenv.hostPlatform) system; # for agenix pkg

  mystuff = pkgs.writeShellScriptBin "echo-secret" ''
        ${pkgs.coreutils}/bin/cat ${config.age.secrets.my_identity.path} > /home/yeshey/Downloads/ImOkay.txt
      '';
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
    ./sshKeys.nix
  ];

  options.myHome.agenix = with lib; {
    enable = mkEnableOption "agenix";
  };

  config = lib.mkIf cfg.enable {

    home.packages = [
      inputs.agenix.packages.${system}.agenix
      mystuff
    ];

    # we need services.openssh enabled in the system (I think)

    # My comment on this https://github.com/ryantm/agenix/issues/50#issuecomment-2119528799
    # Needs a reboot
    /*
    systemd.user.services."test" = {
      Unit = {
        Description = "test";
        After = [ "agenix.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mystuff}/bin/echo-secret";
      };
      Install.WantedBy = [ "default.target" ];
    };
    */

    age = {
      identityPaths = [ "/home/yeshey/.ssh/my_identity" ];
      secrets = {

        my_identity = {
          file = ../../../../secrets/my_identity.age;
          # path = "$HOME/Downloads/mymymymy.txt";
          #mode = "0440";
          #group = config.users.groups.keys.name;
        };

      };
    };

  };
}
