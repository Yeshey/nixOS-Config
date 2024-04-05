{
  description = "My config";

  nixConfig.extra-substituters = [ "https://cache.thalheim.io" "https://numtide.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [
    "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
    "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
  ];

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
      forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];
    in
    rec {
      overlays = {  };

      legacyPackages = forAllSystems (system:
        import inputs.nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config.allowUnfree = true;
        }
      );

      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix { };
        node = nixpkgs.legacyPackages.${system}.callPackage ./shells/node.nix { };
        go = nixpkgs.legacyPackages.${system}.callPackage ./shells/go.nix { };
        python = nixpkgs.legacyPackages.${system}.callPackage ./shells/python.nix { };
        pythonVenv = nixpkgs.legacyPackages.${system}.callPackage ./shells/pythonVenv.nix { };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);

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

      homeConfigurations = {
        # For Non-NixOS
        zoras = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = (builtins.attrValues homeManagerModules) ++ [
            ./home-manager/zoras.nix
          ];
        };

        nix-on-droid = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = (builtins.attrValues homeManagerModules) ++ [
            ./home-manager/nix-on-droid.nix
          ];
        };
      };
    };
}
