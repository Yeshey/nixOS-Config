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

    # TODO can any of these be made into general modules?
    #./dontStarveTogetherServer.nix

    ./nextcloud.nix # TODO not working right boy nixos-rebuild build-vm --flake ~/.setup#skyloft not working
    #./minecraft.nix
    ./openvscode-server.nix # vscoduium is not well
    ./ngix-server
    ./mineclone.nix
    ./kubo.nix
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

  mySystem = {
    gnome.enable = false; # TODO, we can do better
    plasma.enable = false;
    gaming.enable = false;
    vmHost = true;
    dockerHost = true;
    host = "skyloft"; # TODO make this mandatory?
    home-manager = {
      enable = true;
      home = ./home.nix;
      # useGlobalPkgs = lib.mkForce false;
    };
    bluetooth.enable = false;
    printers.enable = false;
    sound.enable = false;
    flatpaks.enable = false;
    #nix.substituters = [ "nasgul" ];
  };
  # mySystem.home-manager.useGlobalPkgs = false;

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
