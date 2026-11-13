{
  flake.modules.nixos.t3code =
    { ... }:
    {
      environment.persistence."/persistent" = {
        directories = [
          { directory = "/var/lib/t3code"; user = "t3code"; group = "t3code"; mode = "u=rwx,g=,o="; }
        ];
      };
    };
}