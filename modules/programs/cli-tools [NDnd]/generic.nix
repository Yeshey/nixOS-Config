{ inputs, ... }:

let
  # https://github.com/niksingh710/nvix
  # Replace `core` with `bare` or `full` as needed
  nvix = pkgs: lib:
    inputs.nvix.packages.${pkgs.stdenv.hostPlatform.system}.bare.extend {
      plugins.avante.enable = lib.mkForce false; # requires copilot setup
      plugins.obsidian.enable = lib.mkForce false; # requires workspace config
    };

  genericPackages = pkgs: lib: with pkgs; [
    git
    tmux
    unstable.devenv
    curl
    vim
    wget
    tree
    btop
    jq
    xdg-utils
    nettools
    dnsutils
    pciutils
    unzip
    ookla-speedtest
    home-manager

    # nvim with nvix and development tools for nvix
    (nvix pkgs lib)
    gcc
    gnumake
    pkg-config
  ];
in
{
  flake.modules.nixos.cli-tools =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = genericPackages pkgs lib;
      programs.htop.enable = true;
    };

  flake.modules.darwin.cli-tools =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = genericPackages pkgs lib;
    };

  flake.modules.homeManager.cli-tools =
    { pkgs, lib, ... }:
    {
      home.packages =
        (genericPackages pkgs lib)
        ++ (with pkgs; [
          ffmpeg-full
          hyfetch
          yt-dlp
          rsync
          file
          killall
          cmatrix
          scrcpy
          ocrmypdf
          libnotify
          xdotool
          gh
          android-tools
          rclone
        ]);
      programs.htop.enable = true;
    };
}