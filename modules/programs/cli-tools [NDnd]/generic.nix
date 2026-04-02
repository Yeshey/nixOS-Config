{ self, ... }:
let
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
  ];
in
{
  flake.modules.nixos.cli-tools =
    { pkgs, lib, ... }:
    {
      imports = [ self.modules.nixos.nvix ];
      environment.systemPackages = genericPackages pkgs lib;
      programs.htop.enable = true;
    };

  flake.modules.darwin.cli-tools =
    { pkgs, lib, ... }:
    {
      imports = [ self.modules.darwin.nvix ];
      environment.systemPackages = genericPackages pkgs lib;
    };

  flake.modules.homeManager.cli-tools =
    { pkgs, lib, ... }:
    {
      imports = [ self.modules.homeManager.nvix ];
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