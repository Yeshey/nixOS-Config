{
  inputs,
  ...
}:
{
  flake.modules.nixos.onikao = 
  { pkgs, ... }:
  {
    imports = with inputs.self.modules.nixos; [
      system-desktop
      plasma-full
      systemd-boot
      btrfs

      # box64-binfmt

      # hosting
      # speedtest-tracker
      # code-server
      xrdp
      vscodium
      # jupyter
      ollama
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.onikao
    ];
    nixpkgs.config.allowUnsupportedSystem = true;
    nixpkgs.config.allowBroken = true;

    environment.systemPackages = with pkgs; [
      github-desktop
    ];

    restic-rclone-backups.jobs.servers = {
      enable           = true;
      user             = "root";
      paths            = [
        "/var/lib/luanti-anarchyMineclone2/world"
        "/srv/minecraft"
        "/opt/docker/overleaf/overleaf-data"
      ];
      rcloneRemoteName = "OneDriveISCTE";
      rcloneRemotePath = "Backups/ResticBackups/servers";
      rcloneConfigFile = "/root/.config/rclone/rclone.conf";
      passwordFile     = builtins.toFile "restic-password" "123456789";
      initialize       = false;
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
      settings.PerSourcePenalties = "no"; # sometimes killed reverse proxy tunnels
    };

    networking.hostName = "onikao"; 
  };
  flake.modules.homeManager.onikao = { };
}
