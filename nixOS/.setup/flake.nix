{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ...}:
    let
      #system = "x86_64-linux";
      #pkgs = import nixpkgs {
      #  inherit system;
      #  config.allowUnfree = true;
      #};
      #lib = nixpkgs.lib;
      location = "$HOME/.setup";
      user = "yeshey";
    in {
      nixosConfigurations = {
        import ./hosts {          # if no files is specified, it will always go to default.nix in the directory                                           # Imports ./hosts/default.nix
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager nur user location doom-emacs hyprland;   # Also inherit home-manager so it does not need to be defined here.
        }
      };

      homeConfigurations = (                                                # Non-NixOS configurations
        import ./nix {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager nixgl user;
        }
      );

    };

}
