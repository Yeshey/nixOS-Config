{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem;
  # Extra caches to pull from (taken from https://discourse.nixos.org/t/package-building-in-flake-despite-provided-substitutes/18107)
  # Shouldn't need to set nixConfig.extra-substituters like this (https://nixos.org/manual/nix/stable/command-ref/conf-file#file-format)
  substituters = {
    cachenixosorg = {
      url = "https://cache.nixos.org";
      key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    };
    #cachethalheimio = {
    #  url = "https://cache.thalheim.io";
    #  key = "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=";
    #};
    numtidecachixorg = {
      url = "https://numtide.cachix.org";
      key = "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=";
    };
    nrdxpcachixorg = {
      url = "https://nrdxp.cachix.org";
      key = "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4=";
    };
    nixcommunitycachixorg = {
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    }; # has cuda
    #nixgaming = {
    #  url = "https://nix-gaming.cachix.org";
    #  key = "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=";
    #};
  };
in
{
  imports = [
    ./user.nix # always active
    ./cliTools.nix # always active
    ./safe-rm.nix # always active
    ./myScripts.nix # always active
    ./gc.nix # always active

    ./androidDevelopment.nix
    ./gaming.nix
    ./gnome.nix
    ./plasma.nix
    ./hyprland.nix
    ./virt.nix
    ./zsh/default.nix
    ./i2p.nix
    ./flatpaks.nix
    ./autoUpgrades.nix
    ./autoUpgradesOnShutdown.nix
    ./browser.nix
    ./hardware/default.nix
    ./syncthing.nix
    ./borgBackups.nix
    ./borgFolderBackups.nix
    ./ssh/default.nix
    ./agenix/default.nix
    ./waydroid.nix
    ./isolateVMsNixStore.nix
    ./impermanence.nix
    ./speedtest-tracker.nix
    ./piperTextToSpeech.nix
    ./snap.nix
    ./autossh.nix
    ./resticRcloneBackups.nix
    ./an-anime-game-launcher.nix
    ./nix-flatpak.nix
    ./nh.nix
    ./allTor.nix
    ./globalprotect.nix
  ];

  options.mySystem = with lib; {
    enable = lib.mkEnableOption "mySystem";
    nix.substituters = mkOption {
      type = types.listOf types.str;
      example = [
        "cachethalheimio"
        "cachenixosorg"
      ];
      # by default use all
      default = mapAttrsToList (name: value: name) substituters; # mapAttrsToList: https://ryantm.github.io/nixpkgs/functions/library/attrsets/#function-library-lib.attrsets.mapAttrsToList
    };
    dataStoragePath = mkOption {
      type = types.str;
      description = "Storage drive or pathosConfig.mySystem.dataStoragePath to put everything";
      default = "/home/${config.mySystem.user}";
    };
    host = mkOption {
      type = types.str;
      description = "Name of the machine, usually what was used in --flake .#hostname. Used for setting the network host name";
      default = "nixOS";
    };
  };

  config = lib.mkMerge [
    {
      # Always activated config
      nixpkgs.overlays = builtins.attrValues outputs.overlays; # needed for it to see the overlays declared in flake.nix
      nixpkgs.config.allowUnfree = true;
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
        (lib.filterAttrs (_: lib.isType "flake")) inputs
      );

      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well, awesome!
      nix.nixPath = [ "/etc/nix/path" ];
      environment.etc = lib.mapAttrs' (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      }) config.nix.registry;

    }
    ( lib.mkIf cfg.enable {
      # Conditional config

      services.geoclue2.enable = true;

      # defaults (enough for a minimal server)
      mySystem.ssh.enable = lib.mkOverride 1010 true;
      mySystem.zsh.enable = lib.mkOverride 1010 true;
      mySystem.hardware.enable = lib.mkOverride 1010 true;

      zramSwap.enable = lib.mkOverride 1010 true;
      programs.htop = {
        enable = true;
        settings = {
          header_layout="two_50_50";
          column_meters_0="LeftCPUs Memory Zram Swap";
          column_meter_modes_0="1 1 1 1";
          column_meters_1="RightCPUs Tasks LoadAverage Uptime";
          column_meter_modes_1="1 2 2 2";
          show_cpu_temperature = 1;
        };
      };
      boot.tmp.cleanOnBoot = lib.mkOverride 1010 true; # delete all files in /tmp during boot.
      boot.supportedFilesystems = [ "ntfs" "btrfs" ]; # lib.mkOverride 1010? Doesn't work with [] and {}?

      #time.timeZone = lib.mkOverride 1010 "Europe/Lisbon";
      services.automatic-timezoned.enable = true;
      services.tzupdate.enable = true; # less accurate, but guarantees correct timezone
      # time.hardwareClockInLocalTime = true;   # match Windows (??? maybe should remove) Nah, I should make windows use UTC instead
      i18n.defaultLocale = lib.mkOverride 1010 "en_GB.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_IDENTIFICATION = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_MEASUREMENT = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_MONETARY = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_NAME = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_NUMERIC = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_PAPER = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_TELEPHONE = lib.mkOverride 1010 "pt_PT.UTF-8"; 
        LC_TIME = lib.mkOverride 1010 "pt_PT.UTF-8"; 
      };
      console.keyMap = lib.mkOverride 1010 "pt-latin1";

      nix = {
        #package = pkgs.nix;
        # remove when nix starts using version 3.10 by default
        package = lib.mkForce pkgs.nixVersions.latest; # needed for clean to work without illigal character error?
        extraOptions =
          # for compression to work with btrfs (https://github.com/NixOS/nix/issues/3550) ...?
          ''
            preallocate-contents = false 
          '';
        settings = {
          experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
          trusted-users = [
            "root"
            "${config.mySystem.user}"
            "@wheel"
          ]; # TODO remove (check the original guys config)
          auto-optimise-store = lib.mkOverride 1010 true;
          #cores = 4; # settings this per machine
          #max-jobs = 2;
          substituters = map (x: substituters.${x}.url) cfg.nix.substituters;
          trusted-public-keys = map (x: substituters.${x}.key) cfg.nix.substituters;
        };
      };

      programs.neovim = {
        enable = true;
        defaultEditor = lib.mkOverride 1010 true;
      };
      programs.command-not-found.enable = true;
      programs.gphoto2.enable = true; # to be able to access cameras
      environment.systemPackages = [ pkgs.kdePackages.kamera 
        pkgs.deploy-rs ];

      networking.networkmanager.enable = lib.mkOverride 1010 true;
      #networking.resolvconf.dnsExtensionMechanism = lib.mkOverride 1010 false; # fixes 
      
      networking.resolvconf.dnsExtensionMechanism = lib.mkOverride 1010 false; # fixes internet connectivity problems with some sites (https://discourse.nixos.org/t/domain-name-resolve-problem/885/2)
      
      #networking.nameservers = [ # (might need this for public WIFIs?)
      #  "1.1.1.1"
      #  "8.8.8.8"
      #  "9.9.9.9"
      #]; # (https://unix.stackexchange.com/questions/510940/how-can-i-set-a-custom-dns-server-within-nixos)
      

      # needed to access coimbra-dev raspberrypi from localnetwork
      #systemd.network.wait-online.enable = lib.mkOverride 1010 false;
      #networking.useNetworkd = lib.mkOverride 1010 true;

      # https://discourse.nixos.org/t/nix-ld-does-not-work-with-virtualenv/39879
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # List by default
          zlib
          zstd
          stdenv.cc.cc
          curl
          openssl
          attr
          libssh
          bzip2
          libxml2
          acl
          libsodium
          util-linux
          xz
          systemd

          # My own additions
          xorg.libXcomposite
          xorg.libXtst
          xorg.libXrandr
          xorg.libXext
          xorg.libX11
          xorg.libXfixes
          libGL
          libva
          pipewire
          xorg.libxcb
          xorg.libXdamage
          xorg.libxshmfence
          xorg.libXxf86vm
          libelf
          
          # Required
          glib
          gtk2
          
          # Without these it silently fails
          xorg.libXinerama
          xorg.libXcursor
          xorg.libXrender
          xorg.libXScrnSaver
          xorg.libXi
          xorg.libSM
          xorg.libICE
          gnome2.GConf
          nspr
          nss
          cups
          libcap
          SDL2
          libusb1
          dbus-glib
          ffmpeg
          # Only libraries are needed from those two
          libudev0-shim

          # needed to run unity
          gtk3
          icu
          libnotify
          gsettings-desktop-schemas
          # https://github.com/NixOS/nixpkgs/issues/72282
          # https://github.com/NixOS/nixpkgs/blob/2e87260fafdd3d18aa1719246fd704b35e55b0f2/pkgs/applications/misc/joplin-desktop/default.nix#L16
          # log in /home/leo/.config/unity3d/Editor.log
          # it will segfault when opening files if you don’t do:
          # export XDG_DATA_DIRS=/nix/store/0nfsywbk0qml4faa7sk3sdfmbd85b7ra-gsettings-desktop-schemas-43.0/share/gsettings-schemas/gsettings-desktop-schemas-43.0:/nix/store/rkscn1raa3x850zq7jp9q3j5ghcf6zi2-gtk+3-3.24.35/share/gsettings-schemas/gtk+3-3.24.35/:$XDG_DATA_DIRS
          # other issue: (Unity:377230): GLib-GIO-CRITICAL **: 21:09:04.706: g_dbus_proxy_call_sync_internal: assertion 'G_IS_DBUS_PROXY (proxy)' failed
          
          # Verified games requirements
          xorg.libXt
          xorg.libXmu
          libogg
          libvorbis
          SDL
          SDL2_image
          glew110
          libidn
          tbb
          
          # Other things from runtime
          flac
          freeglut
          libjpeg
          libpng
          libpng12
          libsamplerate
          libmikmod
          libtheora
          libtiff
          pixman
          speex
          SDL_image
          SDL_ttf
          SDL_mixer
          SDL2_ttf
          SDL2_mixer
          libappindicator-gtk2
          libdbusmenu-gtk2
          libindicator-gtk2
          libcaca
          libcanberra
          libgcrypt
          libvpx
          librsvg
          xorg.libXft
          libvdpau
          # ...
          # Some more libraries that I needed to run programs
          pango
          cairo
          atk
          gdk-pixbuf
          fontconfig
          freetype
          dbus
          alsa-lib
          expat
          # Needed for electron
          libdrm
          mesa
          libxkbcommon
          # Needed to run, via virtualenv + pip, matplotlib & tikzplotlib
          stdenv.cc.cc.lib # to provide libstdc++.so.6
        ];
      };  
            
      networking = {
        hostName = lib.mkOverride 1010 "${cfg.host}";
      };
      
      # networking.useNetworkd = true;
      # networking.firewall.enable = false;

      nixpkgs.config = {
        # allowUnsupportedSystem = true;
        # allowUnfree = true;
        # TODO remove this below 
        permittedInsecurePackages = [ # for package openvscode-server
          #"freeimage-unstable-2021-11-01"
        ];
      };

    })
  ];
}
