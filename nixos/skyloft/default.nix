{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./backups.nix
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

  # set an alias to poweroff ask if you're sure

  mySystem = rec {
    plasma.enable = false;
    gnome.enable = false; # TODO activate both plasma and gnome same time, maybe expose display manager
    ssh.enable = true;
    browser.enable = false;
    cliTools.enable = true;
    zsh.enable = true;
    gaming.enable = false;
    vmHost = true;
    dockerHost = true;
    host = "skyloft";
    user = "yeshey"; # TODO make this into an option where you can do user."yeshey".home-manager.enable ) true etc.
    home-manager = {
      enable = true;
      home = ./home.nix;
    };
    hardware = {
      enable = false;
      #bluetooth.enable = true;
      #printers.enable = true;
      #sound.enable = true;
      #thermald = {
      #  enable = true;
      #  thermalConf = ./thermal-conf.xml;
      #};
      #nvidia.enable = false;
    };
    autoUpgrades = {
      enable = true;
      location = "/home/yeshey/.setup";
      host = "skyloft";
      dates = "weekly";
    };
    flatpaks.enable = false;
    i2p.enable = false;
    syncthing = {
      enable = true;
      dataStoragePath = "/home/${user}";
    };
    androidDevelopment.enable = false;
    agenix = {
      enable = true;
      sshKeys.enable = true;
    };
  };

  toHost = {
    dontStarveTogetherServer = {
      enable = false;
      path = "/home/yeshey/PersonalFiles/Servers/dontstarvetogether/SurvivalServerMadeiraSummer2/DoNotStarveTogetherServer";
    };
    nextcloud.enable = true;
    minecraft.enable = false;
    openvscodeServer.enable = true;
    ngixServer.enable = true;
    mineclone.enable = true;
    kubo.enable = true;
  };

  time.timeZone = "Europe/Madrid";

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    #    allowUnfree = true;
    # TODO remove this below 
    #permittedInsecurePackages = [ # for package openvscode-server
    #  "nodejs-16.20.2"
    #];
  };

  # Remote Desktop with XRDP
  # xfreerdp /v:143.47.53.175 /u:yeshey /dynamic-resolution /audio-mode:1
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  networking.firewall.allowedTCPPorts = [ 3389 ];

  environment.systemPackages = with pkgs; [

  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #powerManagement = { # TODO ???
  #  cpuFreqGovernor = "ondemand";
  #  cpufreq.min = 800000;
  #  cpufreq.max = 4700000;
  #};

  #networking = { # TODO remove?
  #  hostName = "skyloft"; # TODO make into variable
  #};

  system.stateVersion = "22.05";
}
