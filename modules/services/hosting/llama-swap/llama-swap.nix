{ inputs, ... }:
{
  flake.modules.nixos.llama-swap =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      port = 9090;
      stateDir = "/var/lib/llama-swap";
      cacheDir = "/var/cache/llama-swap";
    in
    {
      users.groups.llama-swap = { };
      users.users.llama-swap = {
        isSystemUser = true;
        group = "llama-swap";
      };

      services.llama-swap = {
        enable = true;
        package = pkgs.unstable.llama-swap;
        listenAddress = "0.0.0.0";
        inherit port;
        openFirewall = true;

        settings = {
          healthCheckTimeout = 900;
          logLevel = "info";
        };
      };

      # Upstream sets these without mkDefault, so overrides need mkForce.
      systemd.services.llama-swap.serviceConfig = {
        DynamicUser = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        WorkingDirectory = lib.mkForce stateDir;
        User = "llama-swap";
        Group = "llama-swap";
        StateDirectory = "llama-swap";
        CacheDirectory = lib.mkForce "llama-swap";
      };

      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          {
            directory = cacheDir;
            user = "llama-swap";
            group = "llama-swap";
            mode = "0750";
          }
          {
            directory = stateDir;
            user = "llama-swap";
            group = "llama-swap";
            mode = "0750";
          }
        ];
      };
    };
}