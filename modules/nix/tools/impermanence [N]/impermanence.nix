{
  inputs,
  ...
}:
{

  # convenience function to set persistence settings only,
  # if impermanence module was imported

  flake.lib = {
    mkIfPersistence =
      config: settings:
      if config ? home then
        (if config.home ? persistence then settings else { })
      else
        (if config.environment ? persistence then settings else { });
  };

  flake.modules.nixos.impermanence = {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    environment.persistence."/persistent" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/matches"
        "/var/lib/systemd/timers" # For timers
        "/etc/NetworkManager/system-connections"
        "/root/.config/rclone"
        { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      ];
      files = [
        "/etc/machine-id"
        "/root/.zsh_history"
        "/root/.bash_history"
        { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      ];
    };

    home-manager.sharedModules = [{
      home.persistence."/persistent" = { };
    }];
  };
}
