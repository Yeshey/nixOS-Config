# base config generated with `nix flake init -t github:misterio77/nix-starter-config#standard`
{
  description = "Hyrule";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-plugins = {
      url = "github:LongerHV/neovim-plugins-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nurpkgs.url = "github:nix-community/NUR";
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
    , neovim-plugins
#    , nixgl
    , nix-colors
    , plasma-manager
    , nurpkgs
    , ...
  }@inputs: 
  let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
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
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );
  in rec { # rec makes it pass several times, makes for example nixosModules be visible inside nixosConfigurations
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    #packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options include 'alejandra' & 'nixpkgs-fmt'
    # Using the official nixpkgs formatter (article: https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem)
    formatter = forEachSystem (pkgs: pkgs.unstable.nixfmt-rfc-style);
    # formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-rfc-style);
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});

    # TODO not importing overlays like this anymore? review how to do overlays
    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs outputs;};
    # Overlays
    /*
    overlays = {
      default = import ./overlays/default.nix;
      unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        inherit (nixpkgs-unstable.legacyPackages.${prev.system}) neovim-unwrapped;
      };
      # call the overlays
      neovimPlugins = neovim-plugins.overlays.default;
      # agenix = agenix.overlays.default; # TODO ? remove
      # nixgl = nixgl.overlays.default;
    };
    */

/*
    legacyPackages = forAllSystems (system:
      import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues overlays;
        config.allowUnfree = true;
      }
    );
    */

    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations =
      let
        defaultModules = (builtins.attrValues nixosModules) ++ [
          # agenix.nixosModules.default # for secrets
          home-manager.nixosModules.default
          # plasma-manager.homeManagerModules.plasma-manager
        ];
        specialArgs = { inherit inputs outputs; };
      in
        {
          hyrulecastle = # Lenovo Laptop - Main Machine
            nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              modules = defaultModules ++ [ ./nixos/hyrulecastle ];
            };

          kakariko = # Surface Pro 7 - Portable Machine
            nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              modules = defaultModules ++ [ ./nixos/kakariko ];
            };

          skyloft = # Oracle Arm Ampere - Server
            nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              modules = defaultModules ++ [ ./nixos/skyloft ];
            };

          twilightrealm = # Virtual Machines
            nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              modules = defaultModules ++ [ ./nixos/twilightrealm ];
            };
        };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # For Non-NixOS
      "yeshey@zoras" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux; # Home-manager requires 'pkgs' instance
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
