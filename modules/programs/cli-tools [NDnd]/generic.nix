let
  genericPackages = pkgs: with pkgs; [
    git
    tmux
    htop
    unstable.devenv
    curl
    vim
    wget
    tree
    btop
    jq
    xdg-utils
    home-manager
    local.cowsay
  ];
in
{
  # Called by cli-tools
  flake.modules.nixos.cli-tools = 
    { pkgs, ... }: 
    {
      environment.systemPackages = genericPackages pkgs;
    };

  flake.modules.darwin.cli-tools =
    { pkgs, ... }: 
    {
      environment.systemPackages = genericPackages pkgs;
    };

  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    {
      home.packages =
        (genericPackages pkgs)
        ++ (with pkgs; [
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
        ]);
    };
}
