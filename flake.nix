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
      system = "x86_64-linux";                                # System architecture
      user = "yeshey";
      location = "$HOME/.setup";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;                            # Allow proprietary software
      };

      lib = nixpkgs.lib;
    in {
      nixosConfigurations = (                                 # Location of the available configurations
        import ./hosts {                                      # Imports ./hosts/default.nix
          inherit (nixpkgs) lib;
          inherit inputs user system home-manager;                 # Also inherit home-manager so it does not need to be defined here.
        }
      );

      #homeConfigurations = (                                                # Non-NixOS configurations
      #  import ./nix {
      #    inherit (nixpkgs) lib;
      #    inherit inputs nixpkgs home-manager nixgl user;
      #  }
      #);

    };

}
