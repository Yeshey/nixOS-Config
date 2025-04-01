{ inputs, outputs, ... }:
{
  # call the overlays
  nvimPlugins = inputs.neovim-plugins.overlays.default;
  nur = inputs.nurpkgs.overlays.default; # nur packages available at pkgs.nur

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

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


  x86-packages = final: prev: {
    x86 = let
    in import prev.path {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [
        (final: super: {
          # Add any x86-specific overrides here
        })
      ];
    };
  };

  i686-packages = final: prev: {
    i686 = import prev.path {
      system = "i686-linux";
      config.allowUnfree = true;
      overlays = [
        (final: super: {
          # Add any i686-specific overrides here
        })
      ];
    };
  };



}
