{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

let
  hdaJackRetaskFwContent = ''
[codec]
0x10ec0274 0x10ec11e8 0

[pincfg]
0x12 0xb7a60130
0x13 0x40000000
0x14 0x411111f0
0x15 0x411111f0
0x16 0x411111f0
0x17 0x411111f0
0x18 0x411111f0
0x19 0x90a60160
0x1a 0x411111f0
0x1b 0x90170110
0x1d 0x4066192d
0x1e 0x411111f0
0x1f 0x411111f0
0x21 0x03211020
  '';

  # Create a derivation that produces a directory containing the firmware file
  hdaJackRetaskFwPkg = pkgs.runCommand "hda-jack-retask-custom-fw" {
    # buildInputs can be empty if no tools are needed beyond shell builtins
  } ''
    # Create the standard directory structure for firmware
    mkdir -p $out/lib/firmware
    # Write the content to the firmware file within that structure
    echo "${hdaJackRetaskFwContent}" > $out/lib/firmware/hda-jack-retask.fw
  '';

  # user = "yeshey";

  # TODO find a better way? see if its still needed
  # Wrapper to run steam with env variable GDK_SCALE=2 to scale correctly
  # nixOS wiki on wrappers: https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages
  # Reddit: https://www.reddit.com/r/NixOS/comments/qha9t5/comment/hid3w3z/
  steam-scalled = pkgs.runCommand "steam" { buildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir $out
    # Link every top-level folder from pkgs.steam to our new target
    ln -s ${pkgs.steam}/* $out
    # Except the bin folder
    rm $out/bin
    mkdir $out/bin
    # We create the bin folder ourselves and link every binary in it
    ln -s ${pkgs.steam}/bin/* $out/bin
    # Except the steam binary
    rm $out/bin/steam
    # Because we create this ourself, by creating a wrapper
    makeWrapper ${pkgs.steam}/bin/steam $out/bin/steam \
      --set GDK_SCALE 2 \
      --add-flags "-t"
  '';
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
    ./hardware-configuration.nix
    ./autoUpgradesSurface.nix
    ./boot.nix
    # inputs.learnWithT.nixosModules.default
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
  };

  mySystem = {
    enable = true;
    dataStoragePath = "/mnt/btrfsMicroSD-DataDisk";
    host = "kakariko";
    user = "yeshey"; # TODO make this into an option where you can do user."yeshey".home-manager.enable ) true etc.
    guest.enable = true;
    home-manager = {
      enable = true;
      home = ./home.nix;
    };
    plasma.enable = false;
    gnome = {
      enable = true; # TODO activate both plasma and gnome same time, maybe expose display manager
    };
    hyprland.enable = false;
    ssh = {
      enable = true;
    };
    browser.enable = true;
    cliTools.enable = true;
    zsh.enable = true;
    gaming.enable = true;
    vmHost = true;
    dockerHost = true;
    hardware = {
      enable = true;
      bluetooth.enable = true;
      printers.enable = false;
      sound.enable = true;
      thermald = {
        enable = true;
        thermalConf = ./thermal-conf.xml;
      };
      nvidia.enable = false;
      lvm = {
        enable = false;
        cache.enable = false;
        luks.enable = false;
      };
    };
    autoUpdatesOnShutdown = {
      enable = false;
      location = "github:Yeshey/nixOS-Config";
      host = "kakariko";
      dates = "weekly";
    };
    # autoUpgrades = {
    #   enable = false;
    #   location = "/home/yeshey/.setup";
    #   host = "kakariko";
    #   dates = "weekly";
    # };
    # autoUpgradesSurface = {
    #   enable = false;
    #   location = "github:yeshey/nixOS-Config";
    #   host = "kakariko";
    #   dates = "daily";
    # };
    flatpaks.enable = true;
    i2p.enable = false;
    syncthing = {
      enable = true;
    };

    androidDevelopment.enable = true;

    #agenix = {
    #  enable = false;
    #  sshKeys.enable = false;
    #};
    #isolateVMsNixStore = true;
    waydroid.enable = false;
    impermanence.enable = false;

    speedtest-tracker = {
      enable = false;
      # scheduele = "*/10 * * * *"; # Runs every 10 minutes, default is every hour
    };

    snap.enable = true;
    autossh = {
     enable = true;
     remoteIP = "143.47.53.175";
     remoteUser = "yeshey";
     port = 2333;
    };
    nh.enable = true;
    globalprotect.enable = true;
    rcloneBisync.enable = true;
    virtualbox.enable = true;
  };

  toHost = {
    #remoteWorkstation = {
    #  sunshine.enable = false;
    #  xrdp.enable = false;
    #};
    #dontStarveTogetherServer.enable = false;
    #nextcloud.enable = true;
    #minecraft.enable = false;
    # openvscodeServer = {
    #   enable = false;
    #   desktopItem = {
    #     enable = true;
    #     remote = "oracle";
    #   };
    # };
    #nginxServer.enable = true;
    #mineclone.enable = true;
    #kubo.enable = true;
    #freeGames.enable = false;

    ollama.enable = false;
    searx.enable = false;
  };

  nix = {
    settings = {
      cores = 4; # settings this per machine
      max-jobs = 2;
    };
  };

  boot.kernelParams = [ "usbcore.autosuspend=-1" "clocksource=hpet" ]; # lets see if this fixes connect&disconnect sound bug (I haven't noticed it since)

  # time.hardwareClockInLocalTime = true;   # match Windows (??? maybe should remove) Nah, I should make windows use UTC instead

  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;

  # Enable using internal Mic While headphones connected in jack
  # found out by launching `hdajackretask`, going to Raltek ALC257, set Black Mic Override to "Internal mic"
  # Make the firmware file available to the kernel
  hardware.firmware = [ hdaJackRetaskFwPkg ];
  # Explicitly tell the snd-hda-intel kernel module to load this patch.
  boot.extraModprobeConfig = ''
    options snd-hda-intel patch=hda-jack-retask.fw
  '';

  # learnWithT = {
  #   development.openPorts.enable = true;
  #   appwrite = {
  #     enable = false;
  #   };
  # };

  # tests for games and stuff
  # hardware.opengl = {
  #   enable = true;
  #   driSupport32Bit = true;  # Essential for Proton
  #   extraPackages = with pkgs; [
  #     intel-media-driver     # Vulkan/VA-API for Intel GPUs (Broadwell+)
  #     intel-compute-runtime  # OpenCL support
  #     mesa.drivers           # OpenGL/Vulkan
  #     vulkan-loader          # Vulkan API
  #   ];
  #   extraPackages32 = with pkgs.pkgsi686Linux; [
  #     mesa.drivers           # 32-bit OpenGL/Vulkan
  #     vulkan-loader
  #   ];
  # };

  # virtualisation.docker.storageDriver = "bcachefs"; # for docker

  # Ignore Patterns Syncthing # Ignore Patterns Syncthing # You need to check that this doesnt override every other activation script, make lib.append? - if it was lib.mkFOrce it would override, like this it appends
  system.userActivationScripts =
    let
    #        mkdir -p ${path}
        #echo "${patterns}" > ${path}/.stignore
      ignorePattern = path: patterns: ''
        mkdir -p ${path}
        echo "${patterns}" > ${path}/.stignore
      '';
    in
    {
      # Add ignore patters just for surface here:
      # syncthingIgnorePatterns.text = ''
      #   # MinecraftPrismLauncherMainInstance
      #   ${ignorePattern "/home/yeshey/.local/share/PrismLauncher/instances/MainInstance/.minecraft" "
      #     // *
      #   "}
      # '';
    };

  #boot.kernelModules = [
  #  "coretemp" # for temp sensors in intel (??)
  #];

  # Trusted Platform Module:

  #powerManagement = { # TODO ???
  #  cpuFreqGovernor = "ondemancdd";
  #  cpufreq.min = 800000;
  #  cpufreq.max = 4700000;
  #};

  #boot.extraModulePackages = [
  #  config.boot.kernelPackages.bcachefs
  #];
  #services.bcachefs.autoScrub.enable = true; # enable after you have kernel 6.14 or later
  hardware.microsoft-surface.kernelVersion = "stable"; # newer kernel

  # disable until I can use my powerfull PC to compile the surface pro
  boot.kernelPatches = [
    {
      name = "disable-rust";
      patch = null;
      extraConfig = ''
        RUST n
      '';
    }
  ];

  environment.systemPackages = with pkgs; [
    # jetbrains-toolbox
    # Games
    # steam-scalled
  ];

  # Fix for:
  # jul 15 18:03:07 nixos-kakariko kernel: i915 0000:00:02.0: [drm] Resetting rcs0 for preemption time out
  # jul 15 18:03:07 nixos-kakariko kernel: i915 0000:00:02.0: [drm] WorldOfTanks.ex[6444] context reset due to GPU hang

  # Trying https://devopsx.com/intel-gpu-hang/
  # it was this (I made a comment) https://gitlab.freedesktop.org/mesa/mesa/-/issues/3641

  environment.variables = {
    #MESA_LOADER_DRIVER_OVERRIDE = "i965";
    INTEL_DEBUG = "reemit";
  };

  system.stateVersion = "22.05";
}
