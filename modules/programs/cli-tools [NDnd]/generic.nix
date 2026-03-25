let
  genericPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        tmux
        htop
        unstable.devenv
        curl
        vim # The Nano editor is installed by default.
        wget
        tree
        btop
        jq
        xdg-utils
        home-manager
        local.cowsay
      ];
    };
in
{
  # Called by cli-tools
  flake.modules.nixos.cli-tools = {
    imports = [
      genericPackages
    ];
  };

  flake.modules.darwin.cli-tools = {
    imports = [
      genericPackages
    ];
  };

  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        git
        tmux
        htop
        unstable.devenv
        curl
        vim # The Nano editor is installed by default.
        wget
        tree
        btop
        jq
        xdg-utils

        ffmpeg-full
        yt-dlp # download youtube videos
        rsync
        file
        unzip
        killall
        cmatrix
        scrcpy # screen cast android phone
        ocrmypdf
        libnotify # so you can use notify-send
        xdotool
        gh
        android-tools
        rclone
      ];
    };
}
