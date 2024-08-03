# use this to pass the repo to the phone from the PC
# nix-shell -p android-tools --run "sudo adb push /home/yeshey/.setup/. /data/data/com.termux.nix/files/home/setup/"

{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  android-integration.am.enable = true;
  android-integration.termux-open-url.enable = true;
  android-integration.xdg-open.enable = true;

  # Simply install just the packages
  environment.packages = with pkgs; [
    nano
    git
    openssh
    htop
    tmux
  
    procps
    killall
    diffutils
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip
    unzip
    #proot
    #su
  ];

  home-manager.config = ./home.nix;

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  ''; # allowUnsupportedSystem = true :(

  # Set the default user shell to Zsh
  user = {
    # userName = "yeshey";
    shell = "${pkgs.zsh}/bin/zsh";
  };

  #nixpkgs.config = {
  #  allowUnsupportedSystem = true;
  #};

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

/*
  myHome = {
    user = "yeshey";
    nonNixos.enable = true;
    gnome.enable = false;
    devops.enable = false;
    cli.personalGitEnable = true;
    tmux.enable = true;
    zsh.enable = true;
    neovim = {
      enable = true;
      enableLSP = true;
    };
  };
*/
/*
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
    # Configure your nixpkgs instance
    #config = { # TODO remove or find a better way to use overlays?
    # Disable if you don't want unfree packages
    #  allowUnfree = true;
    #};
  };
  */
}
