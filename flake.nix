{
  description = "A very basic flake";

  inputs = {
    # Release Notes: https://nixos.org/manual/nixos/stable/release-notes.html
    # sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixpkgs
    # sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixos

    # idk if we need any of this
    nixpkgs.url = "github:numtide/nixpkgs-unfree";
    nixpkgs.inputs.nixpkgs.follows = "nixpkgs-23-11";

    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-23-11.url = "github:nixos/nixpkgs/nixos-23.11";

    # https://github.com/nix-community/trustix
    #nixpkgs.url = "github:numtide/nixpkgs-unfree";
    #nixpkgs.inputs.nixpkgs.follows = "nixpkgs-unstable";
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    #nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # https://github.com/numtide/nixpkgs-unfree
    # The unfree instance
    # nixpkgs-unfree.url = "github:numtide/nixpkgs-unfree";
    # nixpkgs-unfree.inputs.nixpkgs.follows = "nixpkgs";

    #nixos-nvidia-vgpu = { # sudo nixos-rebuild --flake ~/.setup#laptop switch --update-input nixos-nvidia-vgpu --impure
    #  type = "path";
    #  path = "/mnt/DataDisk/PersonalFiles/2023/Projects/Programming/nixos-nvidia-vgpu_nixOS/";
    #};
    nixos-nvidia-vgpu.url = "github:Yeshey/nixos-nvidia-vgpu/master";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";
      #url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  # Optionally, pull pre-built binaries from this project's cache https://github.com/numtide/nixpkgs-unfree
  nixConfig.extra-substituters = [ "https://numtide.cachix.org" ];
  #nixConfig.extra-substituters = [ "https://cache.nixos.org/" "https://nixcache.reflex-frp.org" "https://cache.iog.io" "https://digitallyinduced.cachix.org" "https://ghc-nix.cachix.org" "https://ic-hs-test.cachix.org" "https://kaleidogen.cachix.org" "https://static-haskell-nix.cachix.org" "https://tttool.cachix.org" "https://cache.nixos.org/" "https://numtide.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

  outputs = inputs @ { self, nixpkgs, home-manager, nixos-hardware, nixos-nvidia-vgpu, nur, ...}:
    let
      system = "x86_64-linux";                                # System architecture
      user = "yeshey";
      location = "/home/${user}/.setup"; # "$HOME/.setup"

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;                            # Allow proprietary software
      };

      # Not needed apperently?
      #nur-no-pkgs = import nur { # nur packages for home manager (https://github.com/SheetKey/nixos-dotfiles/blob/main/flake.nix)
      #  pkgs = null;
      #  nurpkgs = import nixpkgs { inherit system; };
      #};

      lib = nixpkgs.lib;
    in {
      nixosConfigurations = (                                 # Location of the available configurations
        import ./hosts {                                      # Imports ./hosts/default.nix
          inherit (nixpkgs) lib;
          inherit inputs user location system home-manager nixos-hardware nixos-nvidia-vgpu nur;            # Also inherit home-manager so it does not need to be defined here.
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
