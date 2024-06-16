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
    # ./hardware-configuration.nix 
  ];

  nixpkgs = {
    # You can add overlays here
    hostPlatform = "x86_64-linux";
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

  # Users
  users.users.jonas = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "input" "video" ];
    shell = pkgs.zsh;
    initialHashedPassword = "";
  };
  programs.zsh.enable = true;
  users.users.root.initialHashedPassword = "";
  services.getty.autologinUser = "jonas";
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Hostname
  networking.hostName = "yeshey-nixos-live";

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;
}
