{ inputs, ... }:
{
  flake.modules.nixos.keycloak =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          # Keycloak itself uses DynamicUser + RuntimeDirectory (in /run),
          # so it has no state of its own to persist. All persistent state
          # is in PostgreSQL: realms, users, clients, sessions.
          {
            directory = "/var/lib/postgresql";
            user = "postgres";
            group = "postgres";
            mode = "0700";
          }
        ];
      };
    };
}