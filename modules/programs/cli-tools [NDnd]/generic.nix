{ self, ... }:
let
  genericPackages = pkgs: lib: with pkgs; [
    git
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
    cowsay
  ];
in
{
  flake.modules.nixos.cli-tools =
    { pkgs, lib, ... }:
    {
      imports = with self.modules.nixos; [ nvix tmux ];
      environment.systemPackages = genericPackages pkgs lib;
      programs.htop.enable = true;
    };

  flake.modules.darwin.cli-tools =
    { pkgs, lib, ... }:
    {
      imports = with self.modules.darwin; [ nvix tmux ];
      environment.systemPackages = genericPackages pkgs lib;
    };

  flake.modules.homeManager.cli-tools =
    { pkgs, lib, ... }:
    {
      imports = with self.modules.homeManager; [ nvix tmux ];
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