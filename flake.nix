{
  description = "A very basic flake";

  inputs = {
    # Release Notes: https://nixos.org/manual/nixos/stable/release-notes.html
    # sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixpkgs
    # sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixos
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";

    nixos-nvidia-vgpu.url = "github:danielfullmer/nixos-nvidia-vgpu/master";
    
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, nixos-hardware, nixos-nvidia-vgpu, ...}:
    let
      system = "x86_64-linux";                                # System architecture
      user = "yeshey";
      location = "/home/${user}/.setup"; # "$HOME/.setup"

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;                            # Allow proprietary software
      };

      lib = nixpkgs.lib;
    in {
      nixosConfigurations = (                                 # Location of the available configurations
        import ./hosts {                                      # Imports ./hosts/default.nix
          inherit (nixpkgs) lib;
          inherit inputs user location system home-manager nixos-hardware nixos-nvidia-vgpu;            # Also inherit home-manager so it does not need to be defined here.
        }
      );

      #homeConfigurations = (                                 # Non-NixOS configurations
      #  import ./nix {
      #    inherit (nixpkgs) lib;
      #    inherit inputs nixpkgs home-manager nixgl user;
      #  }
      #);

    };

}
