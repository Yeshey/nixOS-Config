{
  inputs,
  ...
}:
{
  flake.modules.nixos.skyloft = {
    imports = with inputs.self.modules.nixos; [
      system-cli
      plasma-minimal
      systemd-boot
      btrfs
      impermanence

      # hosting
      # speedtest-tracker
      vnstat
      searx
      code-server
      xrdp
      vscodium
      firefox
      open-vpn
      luanti
      jupyter
      ollama
      kubo
      minecraft
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.skyloft
    ];
    nixpkgs.config.allowUnsupportedSystem = true;
    nixpkgs.config.allowBroken = true;
    restic-rclone-backups.jobs.servers = {
      enable           = true;
      user             = "root";
      paths            = [
        "/var/lib/luanti-anarchyMineclone2/world"
        "/srv/minecraft/mainServer/world"
        "/srv/minecraft/familiaLopesTAISCTE"
        "/srv/minecraft/tunaCraft"
        "/opt/docker/overleaf/overleaf-data"
      ];
      rcloneRemoteName = "OneDriveISCTE";
      rcloneRemotePath = "ResticBackups/servers";
      rcloneConfigFile = "/root/.config/rclone/rclone.conf";
      passwordFile     = builtins.toFile "restic-password" "123456789";
      initialize       = true;
      startAt          = "*-*-* 14:00:00";
      randomizedDelaySec = "6h";
      prune.keep = { within = "1d"; daily = 2; weekly = 2; monthly = 6; yearly = 3; };
      exclude = [ "**/.var" "**/RecordedClasses" "**/Games" ];
    };

    my-scripts = {
      enable = true;
      flakeLocation = "/home/yeshey/.setup";
    };

    services.openssh = {
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "no";
    };

    networking.hostName = "skyloft"; 
  };
  flake.modules.homeManager.skyloft = { };
}
