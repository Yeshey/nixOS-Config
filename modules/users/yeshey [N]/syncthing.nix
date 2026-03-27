{ inputs, ... }:

let
  myVersioning = {
    type = "staggered";
    params = {
      cleanInterval = "3600";
      maxAge = "864000";
    };
  };

  allDevices = [
    "nixOS-Laptop"
    "manjaro-Laptop"
    "windows-Laptop"
    "nixOS-Surface"
    "windows-Surface"
    "android-A70Phone"
    "nixOS-arm-oracle"
  ];
in
{
  flake.modules.homeManager.yeshey =
    { lib, config, ... }:
    let
      dataPath = config.yeshey.dataStoragePath;
    in
    {
      services.syncthing.settings = {
        devices = {
          "nixOS-Laptop".id    = "MQJK4CT-TFXHX2Y-3E2BSCD-Q7775YX-SX7VHKF-4TY6OA6-OGZO2QX-3NPTWQN";
          "manjaro-Laptop".id  = "HWPEE67-I7DPOPG-H3A3SDX-5HFJK5W-33OIOUO-S6TD5E7-52OAO3B-OFAUAAF";
          "windows-Laptop".id  = "SST7QBM-2SKF4WK-F4RUAA2-ICQ7NBB-LDI3I33-O3DEZZJ-TVXZ3DB-M7IYTAQ";
          "nixOS-Surface".id   = "SEYY5VY-KFP6VTK-RDUXRJL-DJDZAXT-2FVZHCQ-EEOEJFW-HLAVQKR-6UHBDQN";
          "windows-Surface".id = "4L2C6IN-PG25JP6-46WCN2B-EKFAHPR-3FE3B2F-JCXRQ5T-MO5PDAA-JWU2IA7";
          "android-A70Phone".id = "RT3DBUX-VNP5WPX-TZEYYL5-SVKR27H-432WTFY-JD3JOAA-HTL4APW-GRQIBQC";
          "nixOS-arm-oracle".id = "GRRWAOD-DNXYFHP-TBZIFO7-L2FV6MK-RGLDASJ-ECOU3TA-27DDF4N-QI2WAA7";
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
          "bash&zshHistory" = {
            path       = "~/";
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

      # stignore files — home.file is cleaner than userActivationScripts
      home.file = {
        "PersonalFiles/2029/.stignore".text = ''
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
        '';
        "PersonalFiles/2028/.stignore".text = ''
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
        '';
        "PersonalFiles/2027/.stignore".text = ''
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
        '';
        "PersonalFiles/2026/.stignore".text = ''
          //*
          //(?i)PhotosAndVideos
          .git
          *.ipynb
        '';
        "PersonalFiles/Timeless/Syncthing/PhoneCamera/.stignore".text = ''
          //*
          //(?i)Photos&Videos
        '';
        "PersonalFiles/Timeless/Syncthing/Allsync/.stignore".text = ''
          //*
          //(?i)watch
        '';
        "PersonalFiles/Timeless/Music/.stignore".text = ''
          //*
          (?i)AllMusic
          (?i)AllMusic-mp3
        '';
        ".stignore".text = ''
          !/.zsh_history
          !/.bash_history
          !/.python_history
          // Ignore everything else:
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
    };
}