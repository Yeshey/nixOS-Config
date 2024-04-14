# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  nierWallpaper = builtins.fetchurl {
      url = "https://images6.alphacoders.com/655/655990.jpg";
      sha256 = "b09b411a9c7fc7dc5be312ca9e4e4b8ee354358daa792381f207c9f4946d95fe";
  };
	myWallpaper = builtins.fetchurl {
		url = "https://cdna.artstation.com/p/assets/images/images/018/711/480/large/john-kearney-cityscape-poster-artstation-update.jpg";
		sha256 = "sha256:1a2krq61502z5zka0a97zll4s8x9dv2qaap5hivpr7fpzl46qp2n";
	};

  #import = [ ./wallpapers.nix ];
  # example = pkgs.callPackage ./example { };
}
