{ inputs, outputs, config, lib, pkgs, ... }:

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
    hydranixosorg = {
      url = "https://hydra.nixos.org";
      key = "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=";
    };
    nrdxpcachixorg = {
      url = "https://nrdxp.cachix.org";
      key = "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4=";
    };
    nixcommunitycachixorg = {
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    };
  };
in
{
  imports = [
    ./user.nix
    ./android.nix
    ./gaming.nix
    ./gnome.nix
    ./plasma.nix
    ./virt.nix
    ./zsh

    ./i2p.nix # TODO review and possibly clump together with the non-server Configuration below
    ./bluetooth.nix
    ./sound.nix
    ./printers.nix
    ./flatpaks.nix

    # ./syncthing.nix
  ];

  options.mySystem = with lib; {
    nix.substituters = mkOption {
      type = types.listOf types.str;
      example = ["cachethalheimio" "cachenixosorg"];
      # by default use all
      default = mapAttrsToList (name: value: name) substituters; # mapAttrsToList: https://ryantm.github.io/nixpkgs/functions/library/attrsets/#function-library-lib.attrsets.mapAttrsToList
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
    boot.supportedFilesystems = [ "ntfs" ]; # TODO lib.mkdefault? Doesn't work with [] and {}?

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
      '' + '' 
         experimental-features = nix-command flakes
      '';

      gc = {
        automatic = lib.mkDefault true;
        options = lib.mkDefault "--delete-older-than 14d";
        dates = lib.mkDefault "weekly";
      };
      settings = {
        trusted-users = [ "root" "${config.mySystem.user}" "@wheel" ]; # TODO remove (check the original guys config)
        auto-optimise-store = lib.mkDefault true;
        substituters = map (x: substituters.${x}.url) cfg.nix.substituters;
        trusted-public-keys = map (x: substituters.${x}.key) cfg.nix.substituters;
      };
    };
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nix.nixPath = ["/etc/nix/path"];
    environment.etc =
      lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;

    services.openssh = with lib; {
      enable = true;
      settings.PermitRootLogin = lib.mkDefault "yes"; # TODO no
      settings.X11Forwarding = lib.mkDefault true;
    };
    # security.sudo.wheelNeedsPassword = false; # TODO remove (how do you do secrets management)
    # security.pam.enableSSHAgentAuth = true;

    programs.neovim = {
      enable = true;
      defaultEditor = lib.mkDefault true;
    };
    programs.ssh = {
      startAgent = true;
      forwardX11 = true;
    };
    programs.command-not-found.enable = lib.mkDefault true;

    environment = {
      systemPackages = with pkgs; [
        git
        dnsutils
        pciutils
        vim # The Nano editor is installed by default.
        htop
        tmux
        wget
        tree
        unzip
        unrar # also to extract .rar with ark in KDE # unrar x Lab5.rar
      ];
    };

    networking.networkmanager.enable = lib.mkDefault true;
    networking.resolvconf.dnsExtensionMechanism = lib.mkDefault false; # fixes internet connectivity problems with some sites (https://discourse.nixos.org/t/domain-name-resolve-problem/885/2)
    networking.nameservers = [ "1.1.1.1" "8.8.8.8" "9.9.9.9" ]; # (https://unix.stackexchange.com/questions/510940/how-can-i-set-a-custom-dns-server-within-nixos)
    # needed to access coimbra-dev raspberrypi from localnetwork
    systemd.network.wait-online.enable = lib.mkDefault false;
    networking.useNetworkd = lib.mkDefault true;
    networking = {
      hostName = "nixos-${cfg.host}";
    };


    
  /*
    # TODO Fix & add auto Upgrades, also set it to boot
    # Auto Upgrade
    # a guy told you in nix wiki to make auto upgrades use boot, to be atomic, meaning, that if they get interrupted it's safe. But notice this:
$ sudo nixos-rebuild switch --flake ~/.setup#skyloft && echo "success"          
[...]
abr 08 22:00:50 nixos-skyloft systemd[1]: podman-mineclone-server.service: Consumed 162ms CPU time, received 16.2K IP traffic, sent 4.5K IP traffic.
warning: error(s) occurred while switching to the new configuration

$ sudo nixos-rebuild boot --flake ~/.setup#skyloft && echo "success"            
[...]
warning: Git tree '/home/yeshey/.setup' is dirty
success

# this command makes a podman service fail, notice how I can detect that if fais with switch, but not with boot, if I want to detect that it fails and roll back in the automatic upgrades, I'll probably have to use switch


    system.autoUpgrade = {
      enable = true;
      # dates = "23:01";
      flake = "${location}#${host}"; # my flake online uri is for example github:yeshey/nixos-config#laptop
      flags = [
        # "--upgrade --option fallback false --update-input nixos-hardware --update-input home-manager --update-input nixpkgs || (cd ${location} && git checkout --flake.lock)"

        # "--upgrade" (seems to be redundant) # upgrade NixOS to the latest version in your chosen channel
        # "--option fallback false" # fallback false should force it to use pre-built packages (https://github.com/NixOS/nixpkgs/issues/77971)
        # "--update-input nixos-hardware --update-input home-manager --update-input nixpkgs" # To update all the packages
        # "--commit-lock-file" # commit the new lock file with git
        # || cd ${location} && git checkout -- flake.lock '' # reverts the changes to flake.lock if things went south (doesn't work because the commands in this list they aren't placed in this order in the end)
      ];
      allowReboot = false; # set to false
    };
    systemd.services.nixos-upgrade.serviceConfig = let
      cfg = config.services.nixos-upgrade;
    in {
      # you can follow the service real time with journalctl -f -u nixos-upgrade.service
      # Also worth noting that these only apply to the physical RAM used,
      # they do not include swap space used. 
      # (There is a separate MemorySwapMax setting, but no MemorySwapHigh, it seems.)
      # https://unix.stackexchange.com/questions/436791/limit-total-memory-usage-for-multiple-instances-of-systemd-service
      MemoryHigh = [ "500M" ];
      MemoryMax = [ "2048M" ];

      # https://unix.stackexchange.com/questions/494843/how-to-limit-a-systemd-service-to-play-nice-with-the-cpu
      CPUWeight = [ "20" ];
      CPUQuota = [ "85%" ];
      IOWeight = [ "20" ];
      # this doesn't work yet (https://unix.stackexchange.com/questions/441575/proper-way-to-use-onfailure-in-systemd)
      ExecStopPost= [ "sh -c 'if [ \"$$SERVICE_RESULT\" != \"success\" ]; then cd ${location} && git checkout -- flake.lock; fi'" ];
    };
  */

  };
}
