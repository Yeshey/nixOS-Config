{ inputs, ... }:

let
  myVersioning = {
    type = "staggered";
    params = {
      cleanInterval = "3600";
      maxAge = "259200"; # 3 days
    };
  };

  allDevices =[
    "nixOS-Laptop"
    "windows-Laptop"
    "nixOS-Surface"
    "android-A70Phone"
    "nixOS-arm-oracle"
  ];
in
{
  flake.modules.homeManager.yeshey =
    { config, lib, pkgs, ... }:
    let
      dataPath = config.yeshey.dataStoragePath;

      # Extract all the paths from your Syncthing folder configuration
      folderPaths = lib.mapAttrsToList (name: folder: folder.path) config.services.syncthing.settings.folders;

      # Generate a bash script that iterates over all paths and guarantees the directory exists
      createFoldersScript = lib.concatMapStringsSep "\n" (p: ''
        # Replace leading ~/ with $HOME/ safely
        folderPath="${p}"
        folderPath="''${folderPath/#\~/$HOME}"
        
        $DRY_RUN_CMD mkdir -p "$folderPath"
      '') folderPaths;
    in
    {
      imports = with inputs.self.modules.homeManager;[
        syncthing
      ];

      services.syncthing = {
        overrideFolders = true;
        overrideDevices = true;

        settings = {
          devices = {
            "nixOS-Laptop".id    = "MQJK4CT-TFXHX2Y-3E2BSCD-Q7775YX-SX7VHKF-4TY6OA6-OGZO2QX-3NPTWQN";
            "windows-Laptop".id  = "SST7QBM-2SKF4WK-F4RUAA2-ICQ7NBB-LDI3I33-O3DEZZJ-TVXZ3DB-M7IYTAQ";
            "nixOS-Surface".id   = "SEYY5VY-KFP6VTK-RDUXRJL-DJDZAXT-2FVZHCQ-EEOEJFW-HLAVQKR-6UHBDQN";
            "android-A70Phone".id = "RT3DBUX-VNP5WPX-TZEYYL5-SVKR27H-432WTFY-JD3JOAA-HTL4APW-GRQIBQC";
            "nixOS-arm-oracle".id = "O3DCQYT-OR2L7LJ-TV2OF6Y-G4WB52H-KJJ7AU2-4GJWQHK-S5POYUE-I6XLBQJ";
          };

          folders = {
            "2029" = {
              path       = "${dataPath}/PersonalFiles/2029";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "2028" = {
              path       = "${dataPath}/PersonalFiles/2028";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "2027" = {
              path       = "${dataPath}/PersonalFiles/2027";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "2026" = {
              path       = "${dataPath}/PersonalFiles/2026";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "A70Camera" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Syncthing/PhoneCamera";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "Allsync" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Syncthing/Allsync";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "Music" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Music";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "Servers" = {
              path       = "${dataPath}/PersonalFiles/Servers";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "ssh" = {
              path       = "~/.ssh";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "zshHistory" = {
              path       = "~/.config/zsh";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "MinecraftPrismLauncherMainInstance" = {
              path       = "~/.local/share/PrismLauncher/instances/MainInstance";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "Osu-Lazer" = {
              path       = "~/.local/share/osu";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "Minetest" = {
              path       = "~/.minetest";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "PowderToy" = {
              path       = "~/.local/share/The Powder Toy";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "WhatsAppPictures" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Syncthing/WhatsAppPictures";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "WhatsAppMovies" = {
              path       = "${dataPath}/PersonalFiles/Timeless/Syncthing/WhatsAppMovies";
              devices    = allDevices;
              versioning = myVersioning;
            };
            "ZoteroStorage" = {
              path       = "~/Zotero/storage";
              devices    = allDevices;
              versioning = myVersioning;
            };
          };
        };
      };

      # Files that live inside $HOME — home.file handles these fine.
      home.file = {
        ".config/zsh/.stignore".text = ''
          !.zsh_history
          *
        '';
        ".local/share/PrismLauncher/instances/MainInstance/.stignore".text = ''
          !/.minecraft/saves
          !/.minecraft/mods
          !/.minecraft/shaderpacks
          !/.minecraft/resourcepacks
          !/minecraft/saves
          !/minecraft/mods
          !/minecraft/shaderpacks
          !/minecraft/resourcepacks
          !/*.json
          !/*.cfg
          *
        '';
        ".minetest/.stignore".text = ''
          !/games
          !/worlds
          *
        '';
        ".local/share/osu/.stignore".text = ''
          !/files
          !/files/**
          !/screenshots
          !/screenshots/**
          !/collection.db
          !/client.realm
          *
        '';
      };

      # 1. Automatically create all Syncthing paths before doing anything else
      home.activation.createFolders = 
        lib.hm.dag.entryAfter[ "writeBoundary" ] ''
          ${createFoldersScript}
        '';

      # 2. Write external .stignore files (runs AFTER createFolders so dirs exist)
      # only needed for folders not necessarily in home directory
      home.activation.createExternalSyncthingFiles =
        lib.hm.dag.entryAfter [ "createFolders" ] ''
          
          # -------------------------------------------------------------------
          # 2026
          # -------------------------------------------------------------------
          dest="${dataPath}/PersonalFiles/2026/.stignore"
          if [ ! -f "$dest" ]; then
            $DRY_RUN_CMD tee "$dest" > /dev/null << 'EOF'
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
          EOF
          fi

          # -------------------------------------------------------------------
          # 2027
          # -------------------------------------------------------------------
          dest="${dataPath}/PersonalFiles/2027/.stignore"
          if [ ! -f "$dest" ]; then
            $DRY_RUN_CMD tee "$dest" > /dev/null << 'EOF'
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
          EOF
          fi

          # -------------------------------------------------------------------
          # 2028
          # -------------------------------------------------------------------
          dest="${dataPath}/PersonalFiles/2028/.stignore"
          if [ ! -f "$dest" ]; then
            $DRY_RUN_CMD tee "$dest" > /dev/null << 'EOF'
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
          EOF
          fi

          # -------------------------------------------------------------------
          # 2029
          # -------------------------------------------------------------------
          dest="${dataPath}/PersonalFiles/2029/.stignore"
          if [ ! -f "$dest" ]; then
            $DRY_RUN_CMD tee "$dest" > /dev/null << 'EOF'
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
          EOF
          fi

          # -------------------------------------------------------------------
          # PhoneCamera
          # -------------------------------------------------------------------
          dest="${dataPath}/PersonalFiles/Timeless/Syncthing/PhoneCamera/.stignore"
          if [ ! -f "$dest" ]; then
            $DRY_RUN_CMD tee "$dest" > /dev/null << 'EOF'
          //*
          //(?i)Photos&Videos
          EOF
          fi

          # -------------------------------------------------------------------
          # Allsync
          # -------------------------------------------------------------------
          dest="${dataPath}/PersonalFiles/Timeless/Syncthing/Allsync/.stignore"
          if [ ! -f "$dest" ]; then
            $DRY_RUN_CMD tee "$dest" > /dev/null << 'EOF'
          //*
          //(?i)watch
          EOF
          fi

          # -------------------------------------------------------------------
          # Music
          # -------------------------------------------------------------------
          dest="${dataPath}/PersonalFiles/Timeless/Music/.stignore"
          if [ ! -f "$dest" ]; then
            $DRY_RUN_CMD tee "$dest" > /dev/null << 'EOF'
          //*
          (?i)AllMusic
          (?i)AllMusic-mp3
          EOF
          fi

        '';

      # Workaround for https://github.com/nix-community/home-manager/issues/6933
      home.activation.fixSyncthingStateDir =
        lib.hm.dag.entryAfter[ "writeBoundary" ] ''
          if [ ! -e "$HOME/.local/state/syncthing" ]; then
            $DRY_RUN_CMD ln -s "$HOME/.config/syncthing" "$HOME/.local/state/syncthing"
          fi
        '';
    };
}