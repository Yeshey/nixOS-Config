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

  stremio-scalled = pkgs.runCommand "stremio" { buildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir $out
    # Link every top-level folder from pkgs.stremio to our new target
    ln -s ${pkgs.stremio}/* $out
    # Except the bin folder
    rm $out/bin
    mkdir $out/bin
    # We create the bin folder ourselves and link every binary in it
    ln -s ${pkgs.stremio}/bin/* $out/bin
    # Except the stremio binary
    rm $out/bin/stremio
    # Because we create this ourself, by creating a wrapper
    makeWrapper ${pkgs.stremio}/bin/stremio $out/bin/stremio \
      --set QT_AUTO_SCREEN_SCALE_FACTOR 1 \
      --add-flags "-t"
  '';
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
    ./hardware-configuration.nix
    ./autoUpgradesSurface.nix
    ./boot.nix
    inputs.learnWithT.nixosModules.default
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
        enable = true;
        cache.enable = true;
        luks.enable = true;
      };
    };
    autoUpgrades = {
      enable = false;
      location = "/home/yeshey/.setup";
      host = "kakariko";
      dates = "weekly";
    };
    autoUpgradesSurface = {
      enable = false;
      location = "github:yeshey/nixOS-Config";
      host = "kakariko";
      dates = "daily";
    };
    flatpaks.enable = true;
    i2p.enable = true;
    syncthing = {
      enable = true;
    };

    androidDevelopment.enable = true;

    agenix = {
      enable = false;
      sshKeys.enable = false;
    };
    #isolateVMsNixStore = true;
    impermanence.enable = false;

    speedtest-tracker = {
      enable = true;
      # scheduele = "*/10 * * * *"; # Runs every 10 minutes, default is every hour
    };

    piperTextToSpeech.enable = true;
    snap.enable = true;
    warnElections.enable = true;
  };

  toHost = {
    #remoteWorkstation = {
    #  sunshine.enable = false;
    #  xrdp.enable = false;
    #};
    #dontStarveTogetherServer.enable = false;
    #nextcloud.enable = true;
    #minecraft.enable = false;
    #openvscodeServer.enable = true;
    #ngixServer.enable = true;
    #mineclone.enable = true;
    #kubo.enable = true;
    #freeGames.enable = false;

    ollama.enable = false; 
    searx.enable = false;
  };

  learnWithT = {
    development.openPorts.enable = true;
    appwrite = {
      enable = false;
    };
  };

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
      syncthingIgnorePatterns.text = ''
        # MinecraftPrismLauncher
        ${ignorePattern "/home/yeshey/.local/share/PrismLauncher/instances" "
          *
        "}
      '';
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

  environment.systemPackages = with pkgs; [
    stremio-scalled
    # jetbrains-toolbox
    # Games
    # steam-scalled
  ];

  #networking = { # TODO can you remove
  #  hostName = "kakariko"; # TODO make into variable
  #};

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
