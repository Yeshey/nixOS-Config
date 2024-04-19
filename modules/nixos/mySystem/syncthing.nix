{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.mySystem.syncthing;
in
{
  options.mySystem.syncthing = {
    enable = lib.mkEnableOption "syncthing";
    dataStoragePath = lib.mkOption {
        type = lib.types.path;
        example = /mnt/DataDisk;
      };
  };

  config = lib.mkIf cfg.enable {
    # Open ports in the firewall.
    # Ports for syncthing: https://docs.syncthing.net/users/firewall.html
    networking.firewall.allowedTCPPorts = [ 22000 ]; # for [ syncthing ]
    networking.firewall.allowedUDPPorts = [ 22000 21027 ]; # for [ syncthing syncthing ]
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # Syncthing
    services = {
      syncthing = {
        enable = true;
        user = "${config.mySystem.user}";
        dataDir = "/home/${config.mySystem.user}/Documents";    # Default folder for new synced folders
        configDir = "/home/${config.mySystem.user}/.config/syncthing";   # Folder for Syncthing's settings and keys

        settings = {
          options = {
            relaysEnabled = true;
          };
          devices = {
            "nixOS-Laptop" = { id = "WVB5HBT-QH4536U-T4SHK3I-J6EW2QY-KAW44KE-UFGO4KI-DDYZDKE-FQJUTAK"; };
            "manjaro-Laptop" = { id = "HWPEE67-I7DPOPG-H3A3SDX-5HFJK5W-33OIOUO-S6TD5E7-52OAO3B-OFAUAAF"; };
            "windows-Laptop" = { id = "SST7QBM-2SKF4WK-F4RUAA2-ICQ7NBB-LDI3I33-O3DEZZJ-TVXZ3DB-M7IYTAQ"; };
            "nixOS-Surface" = { id = "PMNJYEZ-VIBNA7A-LW2QYF3-PV4Y36X-6OIAAUN-FWZVBMS-KM4C7C4-SD2IEQC"; };
            "nixOS-VM" = { id = "GNY2ZH4-Y7W67RF-YXAB7KP-6ZYYAVB-OO2RB4I-UXM2J4X-UNLJGEL-77BHWQY"; };
            "windows-Surface" = { id = "4L2C6IN-PG25JP6-46WCN2B-EKFAHPR-3FE3B2F-JCXRQ5T-MO5PDAA-JWU2IA7"; };
            "android-A70Phone" = { id = "MR7NNT5-HWOSMHW-W5U44XG-FIBUI72-OK7AZZW-LH2IKU3-PDSRAAD-OGD3IQQ"; };
            "nixOS-arm-oracle" = { id = "VZHXEOO-QDU4DMZ-NMOSJYI-K5ZFPPQ-TXH2QBV-7YKBHJY-V2XO7KK-HVAHZQZ"; };
          };
          folders = 
            let 
              myVersioning = {
                  type = "staggered"; 
                  params = { 
                    cleanInterval = "3600"; # 1 hour in seconds
                    maxAge = "864000"; # 11 days in seconds
                  }; 
                }; 
            in {
              /*
            "2024" = {
              path = "${cfg.dataStoragePath}/PersonalFiles/2024"; 
              devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Ignore patterns: Recorded_Classes 
            };
            "2023" = {
              path = "${cfg.dataStoragePath}/PersonalFiles/2023"; 
              devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Ignore patterns: Recorded_Classes 
            };
            #"2022" = {
            #  path = "${cfg.dataStoragePath}/PersonalFiles/2022"; 
            #  devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" ]; 
            #  versioning = myVersioning;
              # Ignore patterns: Recorded_Classes 
            #};
            "A70Camera" = {
              path = "${cfg.dataStoragePath}/PersonalFiles/Timeless/Syncthing/PhoneCamera";
              devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Ignore patterns: 
            };
            "Allsync" = {
              path = "${cfg.dataStoragePath}/PersonalFiles/Timeless/Syncthing/Allsync";
              devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: watch
            };
            "Music" = {
              path = "${cfg.dataStoragePath}/PersonalFiles/Timeless/Music";
              devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: AllMusic
            };
            */
            "Servers" = { # So This makes the evaluation of the derivation take infinite space?
              path = "${cfg.dataStoragePath}/PersonalFiles/Servers";
              devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: AllMusic
            };
            # Config and game files sync
            "ssh" = {
              path = "~/.ssh";
              devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: 
            };
            "bash&zshHistory" = { # added ignore batterns with home-manager to sync only those files
              path = "~/";
              devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: 
            };
            "MinecraftPrismLauncher" = {
              path = "~/.local/share/PrismLauncher/instances";
              devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: 
            };
            "Osu-Lazer" = {
              path = "~/.local/share/osu";
              devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: 
            };
            "Minetest" = {
              path = "~/.minetest";
              devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: 
            };
            "PowderToy" = {
              path = "~/.local/share/The Powder Toy/";
              devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: 
            };

            "Mindustry" = {
              path = "~/.local/share/Mindustry/";
              devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" "windows-Surface" "windows-Laptop" "nixOS-arm-oracle"]; 
              versioning = myVersioning;
              # Potencial Ignore patterns: settings.bin settings.log
            };
          };
        };

      };
    };
    # A systemd timer to delete all the sync-conflict files
    systemd.timers."delete-sync-conflicts" = {
      wantedBy = [ "timers.target" ];
        timerConfig = {
          Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
          OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28"; # Every three days approximatley
          Unit = "delete-sync-conflicts.service";
        };
    };
    systemd.services."delete-sync-conflicts" = {
      script = ''
      # Ignore What's inside Trash etc...
        if [ -d "/mnt" ]; then
            ${pkgs.findutils}/bin/find /mnt -mount -mindepth 1 -type f -not \( -path '*/.Trash-1000/*' -or -path '*.local/share/Trash/*' \) -name '*.sync-conflict-*' -ls -delete
        fi

        if [ -d "/home" ]; then
            ${pkgs.findutils}/bin/find /home -mount -mindepth 1 -type f -not \( -path '*/.Trash-1000/*' -or -path '*.local/share/Trash/*' \) -name '*.sync-conflict-*' -ls -delete
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User= "${config.mySystem.user}";
      };
    };

    # Syncthing shortcut, based on webapp manager created shortcut (https://github.com/linuxmint/webapp-manager)
    /*
    ".local/share/applications/vivaldi-syncthing.desktop".source = builtins.toFile "vivaldi-syncthing.desktop" ''
[Desktop Entry]
Version=1.0
Name=Syncthing
Comment=Web App
Exec=vivaldi --app="http://127.0.0.1:8384#" --class=WebApp-Syncthingvivaldi5519 --user-data-dir=/home/yeshey/.local/share/ice/profiles/Syncthingvivaldi5519
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=webapp-manager
Categories=GTK;WebApps;
MimeType=text/html;text/xml;application/xhtml_xml;
StartupWMClass=WebApp-Syncthingvivaldi5519
StartupNotify=true
X-WebApp-Browser=Vivaldi
X-WebApp-URL=http://127.0.0.1:8384#
X-WebApp-CustomParameters=
X-WebApp-Navbar=false
X-WebApp-PrivateWindow=false
X-WebApp-Isolated=true
        ''; */

    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    environment.systemPackages = with pkgs; 
      let
        syncthingWeb = makeDesktopItem {
          name = "Syncthing";
          desktopName = "Syncthing";
          genericName = "Syncthing Web App";
          exec = ''brave --app="http://127.0.0.1:8384#" --class=WebApp-Syncthingbrave5519 --user-data-dir=/home/yeshey/.local/share/ice/profiles/Syncthingbrave5519'';
          icon = "webapp-manager";
          categories = [ "GTK" "X-WebApps" ];
          mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
        };

      in
      [
        syncthingWeb
      ];

  };
}