{
  flake.modules.nixos.luanti =
    { ... }:
    {
      environment.persistence."/persistent" = {
        directories = [
          { directory = "/var/lib/luanti-anarchyMineclone2"; user = "luanti-anarchyMineclone2"; group = "luanti"; mode = "u=rwx,g=rx,o="; }
          { directory = "/var/lib/luanti-anarchyMineclonia"; user = "luanti-anarchyMineclonia"; group = "luanti"; mode = "u=rwx,g=rx,o="; }
        ];
      };
    };
}