{ config, lib, pkgs, inputs, user, location, host, dataStoragePath, ... }:

{
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
      user = "yeshey";
      dataDir = "/home/${user}/Documents";    # Default folder for new synced folders
      configDir = "/home/${user}/.config/syncthing";   # Folder for Syncthing's settings and keys
      devices = {
        "nixOS-Laptop" = { id = "DJEP7AL-WLBELBK-TISRAC6-BS6PEE2-X5LIAVZ-TLMDRUL-CC4SP2Q-TEV5JAA"; };
        "manjaro-Laptop" = { id = "HWPEE67-I7DPOPG-H3A3SDX-5HFJK5W-33OIOUO-S6TD5E7-52OAO3B-OFAUAAF"; };
        "windows-Laptop" = { id = "SST7QBM-2SKF4WK-F4RUAA2-ICQ7NBB-LDI3I33-O3DEZZJ-TVXZ3DB-M7IYTAQ"; };
        "nixOS-Surface" = { id = "7MRGXWS-QWTEGDF-YEIOM3M-5DM627F-DSYTRN3-JUECBF4-6A4Z26Y-PQVAUAC"; };
        "nixOS-VM" = { id = "GNY2ZH4-Y7W67RF-YXAB7KP-6ZYYAVB-OO2RB4I-UXM2J4X-UNLJGEL-77BHWQY"; };
        "windows-Surface" = { id = "4L2C6IN-PG25JP6-46WCN2B-EKFAHPR-3FE3B2F-JCXRQ5T-MO5PDAA-JWU2IA7"; };
        "android-A70Phone" = { id = "H6ETBYH-DGJCL3H-UUI7GJK-EK6WI5I-UFGTVZF-W6HKUPN-I5MOXCL-PDP4BAS"; };
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
        "2023" = {
          path = "${dataStoragePath}/PersonalFiles/2023"; 
          devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Ignore patterns: Recorded_Classes 
        };
        #"2022" = {
        #  path = "${dataStoragePath}/PersonalFiles/2022"; 
        #  devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" ]; 
        #  versioning = myVersioning;
          # Ignore patterns: Recorded_Classes 
        #};
        "A70Camera" = {
          path = "${dataStoragePath}/PersonalFiles/Timeless/Syncthing/PhoneCamera";
          devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Ignore patterns: 
        };
        "Allsync" = {
          path = "${dataStoragePath}/PersonalFiles/Timeless/Syncthing/Allsync";
          devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: watch
        };
        "Music" = {
          path = "${dataStoragePath}/PersonalFiles/Timeless/Music";
          devices = [ "nixOS-Laptop" "manjaro-Laptop" "windows-Laptop" "nixOS-Surface" "windows-Surface" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: AllMusic
        };

        # Config and game files sync
        "ssh" = {
          path = "~/.ssh";
          devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: 
        };
        "bash&zshHistory" = { # added ignore batterns with home-manager to sync only those files
          path = "~/";
          devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: 
        };
        "MinecraftPrismLauncher" = {
          path = "~/.local/share/PrismLauncher/instances";
          devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: 
        };
        "Osu-Lazer" = {
          path = "~/.local/share/osu";
          devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: 
        };
        "Minetest" = {
          path = "~/.minetest";
          devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: 
        };
        "PowderToy" = {
          path = "~/.local/share/The Powder Toy/";
          devices = [ "nixOS-Laptop" "nixOS-Surface" "nixOS-VM" "android-A70Phone" ]; 
          versioning = myVersioning;
          # Potencial Ignore patterns: 
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
      if [ -d "/mnt" ]; then
          ${pkgs.findutils}/bin/find /mnt -mount -mindepth 1 -type f -not \( -path '*/.Trash-1000/*' -or -path '*.local/share/Trash/*' \) -name '*.sync-conflict-*' -ls -delete
      fi

      if [ -d "/home" ]; then
          ${pkgs.findutils}/bin/find /home -mount -mindepth 1 -type f -not \( -path '*/.Trash-1000/*' -or -path '*.local/share/Trash/*' \) -name '*.sync-conflict-*' -ls -delete
      fi
    '';
    # Ignore What's inside Trash etc...
    serviceConfig = {
      Type = "oneshot";
      User= "${user}";
    };
  };
}