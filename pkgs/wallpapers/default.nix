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
    url = "https://cdna.artstation.com/p/assets/images/images/018/711/480/large/john-kearney-cityscape-poster-artstation-update.jpg";
    sha256 = "sha256:01g135ydn19ci1gky48dva1pdb198dkcnpfq6b4g37zlj5vhbx9r"; # TODO, sha always changing?
  };
  stellarCollisionByKuldarleement = builtins.fetchurl {
    url = "file://${current_folder}/StellarCollisionByKuldarLeement.jpg";
    sha256 = "sha256:1bl7d7qm4ln1bg72c8y2d236a0wn31kgji1h6zsf611qa0b43adm";
  };
}