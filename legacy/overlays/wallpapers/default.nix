{ pkgs }:
let
  current_folder = builtins.toString ./.;
in
{
  nierAutomataWallpaper = pkgs.fetchurl {
    url = "https://images6.alphacoders.com/655/655990.jpg";
    sha256 = "b09b411a9c7fc7dc5be312ca9e4e4b8ee354358daa792381f207c9f4946d95fe";
  };
  johnKearneyCityscapePoster = pkgs.runCommand "john-kearney-cityscape-poster-artstation.jpg" { } ''
    cp ${./john-kearney-cityscape-poster-artstation.jpg} $out
  '';
  stellarCollisionByKuldarleement = pkgs.runCommand "StellarCollisionByKuldarLeement.jpg" { } ''
    cp ${./StellarCollisionByKuldarLeement.jpg} $out
  '';
  tunaCoimbra2025 = pkgs.runCommand "tunaCoimbra2025.jpg" { } ''
    cp ${./tunaCoimbra2025.jpg} $out
  '';
  pinkSunsetMinimalHdWallpaper = pkgs.runCommand "pinkSunsetMinimalHdWallpaper.jpg" { } ''
    cp ${./pinkSunsetMinimalHdWallpaper.jpg} $out
  '';
}
