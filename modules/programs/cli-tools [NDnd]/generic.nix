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
          bc
          python3

          unstable.antigravity-hub
          unstable.antigravity-cli # agy
          unstable.antigravity-ide
          unstable.antigravity-acp
          # unstable.t3code
          unstable.codex
          unstable.opencode
          # unstable.cursor-cli
          unstable.grok-build
          # unstable.muse-code
        ]);
      programs.htop.enable = true;
    };
}