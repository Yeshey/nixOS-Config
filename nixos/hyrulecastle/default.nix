{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

let
  # user = "yeshey";
  dataStoragePath = "/mnt/DataDisk";
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    # (import ./configFiles/VM/VM.nix) # TODO
    # (import ./configFiles/dontStarveTogetherServer.nix) # TODO
    # (import ./configFiles/kubo.nix) # for ipfs # TODO
    # (import ./../oracleArmVM/configFiles/ngix-server.nix) # TODO ???
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    #config = { # TODO remove or find a better way to use overlays?
      # Disable if you don't want unfree packages
    #  allowUnfree = true;
    #};
  };

  mySystem = {
    plasma.enable = true;
    gnome.enable = false; # TODO activate both plasma and gnome same time, maybe expose display manager
    cliTools.enable = true;
    zsh.enable = true;
    gaming.enable = true;
    vmHost = true;
    dockerHost = true; 
    host = "hyrulecastle";
    user = "yeshey"; # TODO make this into an option where you can do user."yeshey".home-manager.enable ) true etc.
    home-manager = {
      enable = true;
      home = ./home.nix;
      # useGlobalPkgs = lib.mkForce false;
    };
    autoUpgrades.enable = true;
    bluetooth.enable = true;
    printers.enable = true;
    sound.enable = true;
    flatpaks.enable = true;
    nvidia = {
      enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    
    android.enable = false;
  };

  virtualisation.docker.storageDriver = "btrfs"; # for docker

  hardware.opengl = {
    enable = true;
    extraPackages = [
      pkgs.vaapiVdpau
      pkgs.libvdpau-va-gl
    ];
  };

  #programs.zsh.enable = true;
  #users.users.yeshey.shell = pkgs.zsh;

  # Manage Temperature, prevent throttling
  # https://github.com/linux-surface/linux-surface/issues/221
  # laptop thermald with: https://github.com/intel/thermal_daemon/issues/42#issuecomment-294567400
  services.power-profiles-daemon.enable = true;
  services.thermald = {
    debug = false;
    enable = true;
    configFile = ./thermal-conf.xml; #(https://github.com/linux-surface/linux-surface/blob/master/contrib/thermald/thermal-conf.xml)
  };
  systemd.services.thermald.serviceConfig.ExecStart = let # running with --adaptive ignores the config file. Issue raised: https://github.com/NixOS/nixpkgs/issues/201402
    cfg = config.services.thermald;
      in lib.mkForce ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            --config-file /home/yeshey/.setup/hosts/laptop/configFiles/thermal-conf.xml \
        '';
  # TODO above was like so:
  # user = "yeshey";
  # location = "/home/${user}/.setup"; # "$HOME/.setup"
  /* in lib.mkForce ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            --config-file ${location}/hosts/laptop/configFiles/thermal-conf.xml \
        '';
        */

  # systemctl status borgbackup-job-rootBackup.service/timer
  services.borgbackup.jobs = { # for a local backup
    rootBackup = {
      # Use `sudo borg list -v /mnt/hdd-btrfs/Backups/borgbackup` to check the archives created
      # Use `sudo borg info /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to see details
      # Use `sudo borg extract /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to extract the specified archive to the current directory
      # Use `sudo borg extract /mnt/hdd-btrfs/Backups/borgbackup::nixOS-laptop-rootBackup-2023-08-07T00:00:06 /mnt/DataDisk/PersonalFiles/Timeless/Music/AllMusic/` to extract the specified folder in the archive to the current directory
      # Use `sudo borg break-lock /mnt/hdd-btrfs/Backups/borgbackup/` to remove the lock in case you can't access it, make sure nothing is using it
      # Use `sudo systemctl start borgbackup-job-rootBackup.service` to make a backup right now
      # Watch size of repo: `watch "sudo du -sh /mnt/hdd-btrfs/Backups/borgbackup/ && echo && sudo du -s /mnt/hdd-btrfs/Backups/borgbackup/"`
      # TODO dataStoragePath = "/mnt/DataDisk"; and user = "yeshey";
      # see if the ~ works
      paths = [ "${dataStoragePath}/PersonalFiles" "~"]; 
      # paths = [ "${dataStoragePath}/PersonalFiles" "/home/${user}"]; 
      #paths = [ "/mnt/DataDisk/PersonalFiles" "/home/yeshey"]; 
      exclude = [ 
          # Largest cache dirs
          ".cache"
          "*/cache2" # firefox
          "*/Cache"
          ".config/Slack/logs"
          ".config/Code/CachedData"
          ".container-diff"
          ".npm/_cacache"
          # Work related dirs
          "*/node_modules"
          "*/bower_components"
          "*/_build"
          "*/.tox"
          "*/venv"
          "*/.venv"
          # Personal Home Dirs
          "*cache*"
          "*/Android"
          "*/.gradle"
          "*/.var"
          "*/.cabal"
          "*/.vscode"
          "*/.stremio-server"
          "*/grapejuice"
          "*/baloo"
          "*/share/containers"
          "*/lutris"
          "*/Steam"
          "*/.config"
          "*/Trash"
          "*/Games"

          # Personal Dirs
          "*/RecordedClasses"

       ];
      repo = "/mnt/hdd-btrfs/Backups/borgbackup";
      encryption = {
        mode = "none";
      };
      prune.keep = {
        within = "1d"; # Keep all archives from the last day
        daily = 2; # keep the latest backup on each day, up to 7 most recent days with backups (days without backups do not count)
        weekly = 2; 
        monthly = 6;
        yearly = 3;
      };
      extraCreateArgs = "--stats";
      #encryption = {
      #  mode = "repokey";
      #  passphrase = "secret";
      #};
      compression = "auto,lzma";
      startAt = "*-*-* 00,03,06,09,12,15,18,21:00:00"; # every 3 hours # "*-*-1/3"; # every 3 days # "hourly"; # weekly # daily # *:0/9 every 9 minutes
    };
  };

  boot.loader = {
    timeout = 2;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      device = "nodev";
      useOSProber = true;
      # default = "saved"; # doesn't work with btrfs :(
      extraEntries = ''
        menuentry "Reboot" {
            reboot
        }
        menuentry "Shut Down" {
            halt
        }
        # Option info from /boot/grub/grub.cfg, technotes "Grub" section for more details
        menuentry "NixOS - Console" --class nixos --unrestricted {
        search --set=drive1 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
        search --set=drive2 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
          linux ($drive2)/@/nix/store/ll70jpkp1wgh6qdp3spxl684m0rj9ws4-linux-5.15.68/bzImage init=/nix/store/c2mg9sck85ydls81xrn8phh3i1rn8bph-nixos-system-nixos-22.11pre410602.ae1dc133ea5/init loglevel=4 3
          initrd ($drive2)/@/nix/store/s38fgk7axcjryrp5abkvzqmyhc3m4pd1-initrd-linux-5.15.68/initrd
        }
      '';
    };
  };

  #powerManagement = { # TODO ???
  #  cpuFreqGovernor = "ondemand";
  #  cpufreq.min = 800000;
  #  cpufreq.max = 4700000;
  #};

  #networking = { # TODO can you remove?
  #  hostName = "nixos-${inputs.host}"; # TODO make into variable
  #};

  system.stateVersion = "22.05";
}
