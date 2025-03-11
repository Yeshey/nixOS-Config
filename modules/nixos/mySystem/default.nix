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
    cachethalheimio = {
      url = "https://cache.thalheim.io";
      key = "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=";
    };
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
    };
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
    ./ssh/default.nix
    ./agenix/default.nix
    ./waydroid.nix
    ./isolateVMsNixStore.nix
    ./impermanence.nix
    ./speedtest-tracker.nix
    ./ollama.nix
    ./piperTextToSpeech.nix
    ./snap.nix
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

      # defaults (enough for a minimal server)
      mySystem.ssh.enable = lib.mkOverride 1010 true;
      mySystem.zsh.enable = lib.mkOverride 1010 true;
      mySystem.hardware.enable = lib.mkOverride 1010 true;
      mySystem.hardware.thermald.enable = lib.mkOverride 1010 true;

      zramSwap.enable = lib.mkOverride 1010 true;
      boot.tmp.cleanOnBoot = lib.mkOverride 1010 true; # delete all files in /tmp during boot.
      boot.supportedFilesystems = [ "ntfs" "btrfs" ]; # lib.mkOverride 1010? Doesn't work with [] and {}?

      time.timeZone = lib.mkOverride 1010 "Europe/Lisbon";
      i18n.defaultLocale = lib.mkOverride 1010 "en_GB.utf8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = lib.mkOverride 1010 "pt_PT.utf8";
        LC_IDENTIFICATION = lib.mkOverride 1010 "pt_PT.utf8";
        LC_MEASUREMENT = lib.mkOverride 1010 "pt_PT.utf8";
        LC_MONETARY = lib.mkOverride 1010 "pt_PT.utf8";
        LC_NAME = lib.mkOverride 1010 "pt_PT.utf8";
        LC_NUMERIC = lib.mkOverride 1010 "pt_PT.utf8";
        LC_PAPER = lib.mkOverride 1010 "pt_PT.utf8";
        LC_TELEPHONE = lib.mkOverride 1010 "pt_PT.utf8";
        LC_TIME = lib.mkOverride 1010 "pt_PT.utf8";
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
          ''
          + ''
            experimental-features = nix-command flakes
          '';

        gc = {
          automatic = lib.mkOverride 1010 true;
          options = lib.mkOverride 1010 "--delete-older-than 14d";
          dates = lib.mkOverride 1010 "weekly";
        };
        settings = {
          trusted-users = [
            "root"
            "${config.mySystem.user}"
            "@wheel"
          ]; # TODO remove (check the original guys config)
          auto-optimise-store = lib.mkOverride 1010 true;
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

      #programs.nix-ld.enable = true;
      
      networking = {
        hostName = lib.mkOverride 1010 "nixos-${cfg.host}";
      };
      
      #networking.useNetworkd = true;
      #networking.firewall.enable = false;

      nixpkgs.config = {
        # allowUnsupportedSystem = true;
        #    allowUnfree = true;
        # TODO remove this below 
        permittedInsecurePackages = [ # for package openvscode-server
          
        ];
      };

    })
  ];
}
