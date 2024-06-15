{ lib, fetchurl }:
let
  current_folder = builtins.toString ./.;
in
{
  nierAutomataWallpaper = builtins.fetchurl {
    url = "https://images6.alphacoders.com/655/655990.jpg";
    sha256 = "b09b411a9c7fc7dc5be312ca9e4e4b8ee354358daa792381f207c9f4946d95fe";
  };
  johnKearneyCityscapePoster = builtins.fetchurl {
    url = "file://${current_folder}/john-kearney-cityscape-poster-artstation.jpg";
    sha256 = "sha256:1a2krq61502z5zka0a97zll4s8x9dv2qaap5hivpr7fpzl46qp2n";
  };
  stellarCollisionByKuldarleement = builtins.fetchurl {
    url = "file://${current_folder}/StellarCollisionByKuldarLeement.jpg";
    sha256 = "sha256:1bl7d7qm4ln1bg72c8y2d236a0wn31kgji1h6zsf611qa0b43adm";
  };
}
