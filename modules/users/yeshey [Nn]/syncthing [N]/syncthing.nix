let
  username = "yeshey";

  myVersioning = {
    type = "staggered";
    params = {
      cleanInterval = "3600";
      maxAge = "604800"; # 7 days
    };
  };

  allDevices = [
    "nixOS-Laptop"
    "windows-Laptop"
    "nixOS-Surface"
    "android-A70Phone"
    "nixOS-arm-oracle"
  ];
in
{
  flake.modules.nixos."${username}" =
    { config, ... }:
    let
      dataPath = config.yeshey.dataStoragePath;
    in
    {
      services.syncthing = {
        enable = true;
        user = username;
        dataDir = "/home/${username}/.local/share/syncthing";
        configDir = "/home/${username}/.config/syncthing";

        settings = {
          devices = {
            "nixOS-Laptop".id     = "MQJK4CT-TFXHX2Y-3E2BSCD-Q7775YX-SX7VHKF-4TY6OA6-OGZO2QX-3NPTWQN";
            "windows-Laptop".id   = "SST7QBM-2SKF4WK-F4RUAA2-ICQ7NBB-LDI3I33-O3DEZZJ-TVXZ3DB-M7IYTAQ";
            "nixOS-Surface".id    = "SEYY5VY-KFP6VTK-RDUXRJL-DJDZAXT-2FVZHCQ-EEOEJFW-HLAVQKR-6UHBDQN";
            "android-A70Phone".id = "RT3DBUX-VNP5WPX-TZEYYL5-SVKR27H-432WTFY-JD3JOAA-HTL4APW-GRQIBQC";
            "nixOS-arm-oracle".id = "ZBHC3YL-LFFBP3E-ZJTUVJ5-3T76GOU-XUFP2UK-SQAKS7N-N7UVM2W-NZIBJQY";
          };

          folders = {
            "PersonalFiles" = {
              path = "${dataPath}/PersonalFiles";
              devices = allDevices;
              versioning = myVersioning;
              ignorePatterns = [
                # Nested syncthing folders
                "/Timeless/Syncthing/WhatsAppMovies"
                "/Timeless/Syncthing/WhatsAppPictures"
                "/Timeless/Syncthing/A70Camera"
                "(?i)AllMusic"
                "(?i)AllMusic-mp3"

                # Structure: what to sync
                "!/2026"
                "!/2027"
                "!/2028"
                "!/2029"
                "!/Timeless/Music"
                "!/Timeless/Syncthing"
                "/Timeless/*"
                "!/Timeless"
                "/*"

                # Junk patterns (global excludes — match inside synced dirs)
              ] ++ (import ./global-excludes.nix-data);
            };

            "WhatsAppMovies" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Syncthing/WhatsAppMovies";
              devices    = allDevices;
              versioning = myVersioning;
            };

            "WhatsAppPictures" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Syncthing/WhatsAppPictures";
              devices    = allDevices;
              versioning = myVersioning;
            };
            
            "A70Camera" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Syncthing/A70Camera";
              devices    = allDevices;
              versioning = myVersioning;
            };

            "ssh" = {
              path       = "/home/${username}/.ssh";
              devices    = allDevices;
              versioning = myVersioning;
            };

            "zshHistory" = {
              path       = "/home/${username}/.config/zsh";
              devices    = allDevices;
              versioning = myVersioning;
              ignorePatterns = [
                "!.zsh_history"
                "*"
              ];
            };

            "MinecraftPrismLauncherMainInstance" = {
              path       = "/home/${username}/.local/share/PrismLauncher/instances/MainInstance";
              devices    = allDevices;
              versioning = myVersioning;
              ignorePatterns = [
                "!/.minecraft/saves"
                "!/.minecraft/mods"
                "!/.minecraft/shaderpacks"
                "!/.minecraft/resourcepacks"
                "!/minecraft/saves"
                "!/minecraft/mods"
                "!/minecraft/shaderpacks"
                "!/minecraft/resourcepacks"
                "!/*.json"
                "!/*.cfg"
                "*"
              ];
            };

            "Osu-Lazer" = {
              path       = "/home/${username}/.local/share/osu";
              devices    = allDevices;
              versioning = myVersioning;
              ignorePatterns = [
                "!/files"
                "!/files/**"
                "!/screenshots"
                "!/screenshots/**"
                "!/collection.db"
                "!/client.realm"
                "*"
              ];
            };

            "Minetest" = {
              path       = "/home/${username}/.var/app/org.luanti.luanti/.minetest";
              devices    = allDevices;
              versioning = myVersioning;
              ignorePatterns = [
                "!/games"
                "!/worlds"
                "*"
              ];
            };

            "PowderToy" = {
              path       = "/home/${username}/.local/share/The Powder Toy";
              devices    = allDevices;
              versioning = myVersioning;
            };

            "ZoteroStorage" = {
              path       = "/home/${username}/Zotero/storage";
              devices    = allDevices;
              versioning = myVersioning;
            };
          };
        };
      };
    };
}