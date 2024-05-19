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
  ];

  options.mySystem.agenix = with lib; {
    enable = mkEnableOption "agenix";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ inputs.agenix.packages.${system}.agenix ]; # adds agenix

    # to provide key for agenix
    openssh = {
      enable = true;
      # openFirewall = false;
    };

    age = {
      secrets = {

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
