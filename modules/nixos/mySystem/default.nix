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
    nixgaming = {
      url = "https://nix-gaming.cachix.org";
      key = "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=";
    };
  };
in
{
  imports = [
    ./user.nix
    ./androidDevelopment.nix
    ./gaming.nix
    ./gnome.nix
    ./plasma.nix
    ./hyprland.nix
    ./virt.nix
    ./zsh

    ./i2p.nix # TODO review and possibly clump together with the non-server Configuration below
    ./flatpaks.nix
    ./cliTools.nix
    ./autoUpgrades.nix
    ./autoUpgradesOnShutdown.nix
    ./browser.nix
    ./hardware

    ./syncthing.nix
    ./borgBackups.nix
    ./ssh
    ./agenix
    ./waydroid.nix
  ];

  options.mySystem = with lib; {
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
      description = "Storage drive to put everything";
      default = "/home/${config.mySystem.user}/Documents";
      # default = builtins.attrValues substituters; # TODO, make it loop throught the list # by default use all
    };
    host = mkOption {
      type = types.str;
      description = "Name of the machine, usually what was used in --flake .#hostname. Used for setting the network host name";
      # default = 
      # default = builtins.attrValues substituters; # TODO, make it loop throught the list # by default use all
    };
    # dedicatedServer = lib.mkEnableOption "dedicatedServer"; # TODO use this to say in the config if it is a dedicatedServer or not, with sub-options to enable each the bluetooth, printers, and sound, ponder adding the gnome and plasma desktops and gaming too
  };

  config = {
    zramSwap.enable = lib.mkDefault true;
    boot.tmp.cleanOnBoot = lib.mkDefault true; # delete all files in /tmp during boot.
    boot.supportedFilesystems = [ "ntfs" "btrfs" ]; # TODO lib.mkdefault? Doesn't work with [] and {}?

    time.timeZone = lib.mkDefault "Europe/Lisbon";
    i18n.defaultLocale = lib.mkDefault "en_GB.utf8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = lib.mkDefault "pt_PT.utf8";
      LC_IDENTIFICATION = lib.mkDefault "pt_PT.utf8";
      LC_MEASUREMENT = lib.mkDefault "pt_PT.utf8";
      LC_MONETARY = lib.mkDefault "pt_PT.utf8";
      LC_NAME = lib.mkDefault "pt_PT.utf8";
      LC_NUMERIC = lib.mkDefault "pt_PT.utf8";
      LC_PAPER = lib.mkDefault "pt_PT.utf8";
      LC_TELEPHONE = lib.mkDefault "pt_PT.utf8";
      LC_TIME = lib.mkDefault "pt_PT.utf8";
    };
    console.keyMap = lib.mkDefault "pt-latin1";

    nixpkgs.overlays = builtins.attrValues outputs.overlays; # TODO what is this, do I need?
    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.nix;
      extraOptions =
        # for compression to work with btrfs (https://github.com/NixOS/nix/issues/3550) ...?
        ''
          preallocate-contents = false 
        ''
        + ''
          experimental-features = nix-command flakes
        '';

      gc = {
        automatic = lib.mkDefault true;
        options = lib.mkDefault "--delete-older-than 14d";
        dates = lib.mkDefault "weekly";
      };
      settings = {
        trusted-users = [
          "root"
          "${config.mySystem.user}"
          "@wheel"
        ]; # TODO remove (check the original guys config)
        auto-optimise-store = lib.mkDefault true;
        substituters = map (x: substituters.${x}.url) cfg.nix.substituters;
        trusted-public-keys = map (x: substituters.${x}.key) cfg.nix.substituters;
      };
    };
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

    programs.neovim = {
      enable = true;
      defaultEditor = lib.mkDefault true;
    };
    programs.command-not-found.enable = lib.mkDefault true;
    environment.systemPackages = [ pkgs.deploy-rs ];

    networking.networkmanager.enable = lib.mkDefault true;
    networking.resolvconf.dnsExtensionMechanism = lib.mkDefault false; # fixes internet connectivity problems with some sites (https://discourse.nixos.org/t/domain-name-resolve-problem/885/2)
    networking.nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "9.9.9.9"
    ]; # (https://unix.stackexchange.com/questions/510940/how-can-i-set-a-custom-dns-server-within-nixos)
    # needed to access coimbra-dev raspberrypi from localnetwork
    systemd.network.wait-online.enable = lib.mkDefault false;
    networking.useNetworkd = lib.mkDefault true;
    networking = {
      hostName = "nixos-${cfg.host}";
    };

    #networking.useNetworkd = true;
    #networking.firewall.enable = false;
  };
}
