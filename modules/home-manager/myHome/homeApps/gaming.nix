{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.gaming;

  downloadAndRunOsu = pkgs.writeShellScriptBin "downloadAndRunOsu"
''
if [ ! -f /tmp/osu.AppImage ]; then
    echo 'Downloading osu.AppImage...'
    ${pkgs.curl}/bin/curl -L https://github.com/ppy/osu/releases/latest/download/osu.AppImage -o /tmp/osu.AppImage
else
    echo 'osu.AppImage already exists in /tmp.'
fi
DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 ${pkgs.appimage-run}/bin/appimage-run /tmp/osu.AppImage
'';
in
let
  osuLazerOfficial = pkgs.makeDesktopItem {
    name = "Osu! Lazer Official AppImage";
    desktopName = "Osu! Lazer Official AppImage";
    #genericName = "Osu Lazer Official AppImage";
    exec = "${downloadAndRunOsu}/bin/downloadAndRunOsu %f";
    icon = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/ppy/osu/refs/heads/master/osu.Desktop/lazer.ico";
      sha256 = "sha256:0m7dl7arnzn1cz02dyv34dp0rp3d67jrvhxa0ysl4hlxzw9ra3gg";
    };
    categories = [
      "Game"
    ];
    type = "Application";
    terminal = true;
  };
in
{
  options.myHome.homeApps.gaming = with lib; {
    enable = mkEnableOption "gaming";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {
    home.packages = with pkgs; [
      # Games
      # unstable.osu-lazer
      lutris
      bottles
      # tetrio-desktop # runs horribly, better on the web
      prismlauncher # polymc # prismlauncher # for Minecraft
      heroic
      minetest
      the-powder-toy

      osuLazerOfficial
    ];

  };
}
