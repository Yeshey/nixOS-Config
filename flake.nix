{
  description = "My config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    /* 
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    }; 
    nixos-nvidia-vgpu.url = "github:Yeshey/nixos-nvidia-vgpu/master";
    */ 

    /* agenix = { # For secrets management
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    }; */
    /* neovim-plugins = {
      url = "github:LongerHV/neovim-plugins-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    }; */
    /* nixgl = { # Might be needed for non-nixOS setups
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    }; */
    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixos-hardware
    , home-manager
#    , agenix
#    , neovim-plugins
#    , nixgl
    , ...
  }@inputs: 
  let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options include 'alejandra' & 'nixpkgs-fmt'
    # Using the official nixpkgs formatter (article: https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem)
    formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-rfc-style);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations =
      let
        defaultModules = (builtins.attrValues nixosModules) ++ [
          # agenix.nixosModules.default # for secrets
          home-manager.nixosModules.default
        ];
        specialArgs = { inherit inputs outputs; };
      in
      {
        hyrule = nixpkgs.lib.nixosSystem { # Lenovo Laptop - Main Machine
          inherit specialArgs;
          modules = defaultModules ++ [
            ./nixos/hyrule
          ];
        };
        kakariko = nixpkgs.lib.nixosSystem { # Surface Pro 7 - Portable Machine
          inherit specialArgs;
          modules = defaultModules ++ [
            ./nixos/kakariko
          ];
        };
        skyloft = nixpkgs.lib.nixosSystem { # Oracle Arm Ampere - Server
          inherit specialArgs;
          modules = defaultModules ++ [
            ./nixos/skyloft
          ];
        };
        twilightrealm = nixpkgs.lib.nixosSystem { # Virtual Machines
          inherit specialArgs;
          modules = defaultModules ++ [
            ./nixos/twilightrealm
          ];
        };
      };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # For Non-NixOS
      "yeshey@zoras" = home-manager.lib.homeManagerConfiguration {
        pkgs = legacyPackages.exodus-linux;
        extraSpecialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues homeManagerModules) ++ [
          ./home-manager/home.nix
        ];
      };

      #"yeshey@nix-on-droid" = home-manager.lib.homeManagerConfiguration {
      #  pkgs = legacyPackages.x86_64-linux;
      #  extraSpecialArgs = { inherit inputs outputs; };
      #  modules = (builtins.attrValues homeManagerModules) ++ [
      #    ./home-manager/nix-on-droid.nix
      #  ];
      #};
    };

  };
}
