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
    # inputs.agenix.nixosModules.default
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

    systemd.user.services."test" = {
      # before = [ "shutdown.target" "reboot.target" ];
      #script = ''
      #  # cat ${config.age.secrets.my_identity.path} > /home/yeshey/Downloads/test.txt
      #  ${pkgs.coreutils}/bin/cat /home/yeshey/Downloads/therealthing.txt > /home/yeshey/Downloads/test.txt
      #'';
      Unit = {
        Description = "test";
        After = [ "agenix.service" ];
      };
      Service = {
        #User = "yeshey";
        Type = "oneshot";
        ExecStart = "${mystuff}/bin/echo-secret";
        #RemainAfterExit="true";
      };
      Install.WantedBy = [ "default.target" ];
      #wantedBy = [ "final.target" ]; # [ "shutdown.target" ];
    };


    #home.file."Downloads/mySecret.txt".source = builtins.toFile "mySecret.txt" ''
    #  $(${pkgs.coreutils}/bin/cat ${config.age.secrets.my_identity.path})
    #'';

/*
    systemd.user.services."mytest" = {
      script = ''
        cat ${config.age.secrets.my_identity.path} > $HOME/Downloads/
      '';
      Service = {
        Type = "oneshot";
      };
    }; */

    age = {
      identityPaths = [ "/home/yeshey/.ssh/my_identity" ];
      secrets = {

        my_identity = {
          file = ../../../secrets/my_identity.age;
          # path = "$HOME/Downloads/mymymymy.txt";
          #mode = "0440";
          #group = config.users.groups.keys.name;
        };

        /*
        # Nix-serve
        cache_priv_key.file = ../../../secrets/nasgul_cache_priv_key.pem.age;

        # Nix (github token)
        extra_access_tokens = {
          file = ../../../secrets/extra_access_tokens.age;
          mode = "0440";
          group = config.users.groups.keys.name;
        };

        # SMTP (sendgrid)
        sendgrid_token = {
          file = ../../../secrets/nasgul_sendgrid_token.age;
          mode = "0440";
          group = "sendgrid";
        };

        # Traefik
        cloudflare_email = {
          file = ../../../secrets/cloudflare_email.age;
          owner = "traefik";
        };
        cloudflare_token = {
          file = ../../../secrets/cloudflare_token.age;
          owner = "traefik";
        };

        # Restic
        restic_credentials = {
          file = ../../../secrets/nasgul_restic_s3_key.age;
          mode = "0440";
          group = "restic";
        };
        restic_password = {
          file = ../../../secrets/nasgul_restic_password.age;
          mode = "0440";
          group = "restic";
        };
        */
      };
    };

  };
}
