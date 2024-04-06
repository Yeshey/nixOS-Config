{inputs, ...}: {
  # TODO check if this can be put in one of the others
  #default = final: prev: {
  #  nierWallpaper = builtins.fetchurl {
  #    url = "https://images6.alphacoders.com/655/655990.jpg";
  #    sha256 = "b09b411a9c7fc7dc5be312ca9e4e4b8ee354358daa792381f207c9f4946d95fe";
  #  };
  #};

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
  # TODO, check if this is right
      #unstable = final: prev: {
      #  unstable = nixpkgs-unstable.legacyPackages.${prev.system};
      #  inherit (nixpkgs-unstable.legacyPackages.${prev.system}) neovim-unwrapped;
      #};

  # call the overlays
  # Used here: pkgs.nvimPlugins.plenary # TODO see if there is a better way to do this
  neovimPluginsss = inputs.neovim-plugins.overlays.default;
}