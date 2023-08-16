#
#  Specific system configuration settings for desktop
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ ./desktop
#   │        ├─ default.nix *
#   │        └─ hardware-configuration.nix
#   └─ ./modules
#       └─ ./desktop
#           └─ ./qemu
#               └─ default.nix
#

{ config, pkgs, user, location, dataStoragePath, lib, ... }:

#let
#        ipDerivation = pkgs.runCommand "${pkgs.busybox}/bin/ip" {} ''
#          ${pkgs.busybox}/bin/ip -4 route get 8.8.8.8 | awk '{print $7}' > "$out";
#          # Or ip a | grep "scope" | grep -Po '(?<=inet )[\d.]+' | head -n 2 | tail -n 1
#          echo "$out";
#          #echo $(${pkgs.busybox}/bin/ip a);
#          jskdhjaskhdaskj
#        '';
#        ipAddress = builtins.readFile ipDerivation;
#      in
{
  imports = [
    (import ./hardware-configuration.nix)

    (import ./configFiles/VM.nix)
    # (import ./configFiles/dontStarveTogetherServer.nix)
    (import ./configFiles/kubo.nix) # for ipfs
    (import ./../oracleArmVM/configFiles/ngix-server.nix)
  ];

  # Manage Temperature, prevent throttling
  # https://github.com/linux-surface/linux-surface/issues/221
  # laptop thermald with: https://github.com/intel/thermal_daemon/issues/42#issuecomment-294567400
  services.power-profiles-daemon.enable = true;
  services.thermald = {
    debug = false;
    enable = true;
    configFile = ./configFiles/thermal-conf.xml; #(https://github.com/linux-surface/linux-surface/blob/master/contrib/thermald/thermal-conf.xml)
  };
  systemd.services.thermald.serviceConfig.ExecStart = let # running with --adaptive ignores the config file. Issue raised: https://github.com/NixOS/nixpkgs/issues/201402
    cfg = config.services.thermald;
  in lib.mkForce ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            --config-file ${location}/hosts/laptop/configFiles/thermal-conf.xml \
        '';

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
      paths = [ "${dataStoragePath}/PersonalFiles" "/home/${user}"]; 
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
      startAt = "*:0/3"; # every 3 hours # "*-*-1/3"; # every 3 days # "hourly"; # weekly # daily # *:0/9 every 9 minutes
    };
  };

  # hardware.enableAllFirmware = true; #?

  # Binary Cache for Haskell.nix
  #nix.settings.trusted-public-keys = [
  #  "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
  #];
  #nix.settings.substituters = [
  #  "https://cache.iog.io"
  #];

  # Make a virtual screen: (as per these instructions: https://github.com/Yeshey/TechNotes/blob/main/techNotes.md#117-use-laptop-as-a-second-monitor)
  /*systemd.services.virtual-display = {
    description = "/etc/X11/xorg.conf.d/30-virtscreen.conf to have a second virtual display";
    serviceConfig.PassEnvironment = "DISPLAY";
    script = ''

      CONFIG_FILE="/etc/X11/xorg.conf.d/30-virtscreen.conf"

      echo 'Section "Device"
          Identifier  "nvidiagpu"
          Driver      "nvidia"
      EndSection

      Section "Screen"
          Identifier  "nvidiascreen"
          Device      "nvidiagpu"
          Option      "ConnectedMonitor" "LVDS-0,DP-1,DP-2"
      EndSection' > "$CONFIG_FILE"

      echo "Configuration written to $CONFIG_FILE."
    '';
    wantedBy = [ "multi-user.target" ]; # starts after login
  }; */

#     ___            __ 
#    / _ )___  ___  / /_
#   / _  / _ \/ _ \/ __/
#  /____/\___/\___/\__/      

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

  # Docker 
  # Docker to automatically grab Epic Games Free games
  # Follow the service log with `journalctl -fu podman-epic_games.service`
  # You have to put the config.json5 file in /mnt/Epic_Games_Claimer/config.json5

  /*
  # My epic games accounts are not very well trusted anymore...
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true; # Big WTF
  # Help from https://github.com/NixOS/nixpkgs/issues/68349 and https://docs.docker.com/storage/storagedriver/btrfs-driver/
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.oci-containers.containers = {
    epic_games = {
      image = "charlocharlie/epicgames-freegames:latest";
      volumes = [ "/mnt/Epic_Games_Claimer:/usr/app/config:rw" ];
      ports = [ "3000:3000" ];
      # extraOptions = [ "-p 3000:3000"];
      # autoStart = true;
    };
  };
  */

  # KDE Plasma
  services.xserver = {
    enable = true; # Enable the X11 windowing system.
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "yeshey";
      sddm = {
        enable = true;
      };
      defaultSession = "plasma"; # "none+bspwm" or "plasma"
    };
    desktopManager.plasma5 = {
      enable = true;
      # supportDDC = true; # doesnt work with nvidia # to support changing brightness for external monitors (https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800)
    };
    # windowManager.bspwm.enable = true; # but doesn't work
  };

  # OVERLAYS
  #nixpkgs.overlays = [                          # This overlay will pull the latest version of Discord (but I guess it doesnt work)
  #];

  # Check configuration: onedrive --display-config
  # config file documentation: https://github.com/abraunegg/onedrive/blob/master/docs/USAGE.md#configuration (get the default config file if you don't have any: wget https://raw.githubusercontent.com/abraunegg/onedrive/master/config -O ~/.config/onedrive/config)
  # change config file here: /home/yeshey/.config/onedrive-0/config (and /home/yeshey/.config/onedrive/config?)
  # nixOS documentation: https://nixos.wiki/wiki/OneDrive
  services.onedrive= {
    enable = true;
  #  package = pkgs.onedrive;
  };
  # To view real time logs: journalctl --user -t onedrive --follow
  # Or maybe better: watch "systemctl --user status onedrive@onedrive-0.service"


  environment.systemPackages = with pkgs; [

    # Epic_Games_Claimer
    # docker

    # tmp
    # virtualbox
    # texlive.combined.scheme-full # LaTeX
    #LookingGlassB6

    # FOR PLASMA DESKTOP
    scrot # for plasma config saver widget
    kdialog # for plasma config saver widget
    ark # Compress and Uncompress files
    sddm-kcm # for sddm configuration in settings
    kate # KDEs notepad    
  ];

  # Syncthing, there's no easy way to add ignore patters, so we're doing it like this for now:
  # But it looks like there also isn't an easy way to add them like we can in home manager with file.source...

}
