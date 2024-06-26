# base config generated with `nix flake init -t github:misterio77/nix-starter-config#standard`
{
  description = "Hyrule";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-plugins = {
      url = "github:LongerHV/neovim-plugins-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nurpkgs.url = "github:nix-community/NUR";
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-nvidia-vgpu = {
      url = "github:Yeshey/nixos-nvidia-vgpu/535.129";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    #nixos-nvidia-vgpu = { # sudo nixos-rebuild --flake ~/.setup#laptop switch --update-input nixos-nvidia-vgpu --impure
    #  type = "path";
      #path = "/mnt/DataDisk/Downloads/nixos-nvidia-vgpu/";
    #  path = "/mnt/DataDisk/PersonalFiles/2023/Projects/Programming/nixos-nvidia-vgpu_nixOS/";
      #inputs.nixpkgs.follows = "nixpkgs-special";
    #};
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = { # For secrets management
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    /*
      nixgl = { # Might be needed for non-nixOS setups
        url = "github:guibou/nixGL";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    */

    /*
    lanzaboote = { # for secure boot
      url = "github:nix-community/lanzaboote/v0.3.0";
      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    }; */
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      home-manager,
      agenix,
      neovim-plugins,
      #    , nixgl
      deploy-rs,
      stylix,
      plasma-manager,
      nurpkgs,
      hyprland-plugins,
      nixos-nvidia-vgpu,
      nixos-generators,
      impermanence,
      # lanzaboote,
      ...
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
    in
    rec {
      # rec makes it pass several times, makes for example nixosModules be visible inside nixosConfigurations
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      #packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      # Formatter for your nix files, available through 'nix fmt'
      # Other options include 'alejandra' & 'nixpkgs-fmt'
      # Using the official nixpkgs formatter (article: https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem)
      formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt); # need to change to nixfmt-rfc-style when possible
      # for now I can use this to format the repo: `nix-shell -p nixfmt-rfc-style -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/e89cf1c932006531f454de7d652163a9a5c86668.tar.gz --run "nixfmt ."`
      # formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-rfc-style);
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });

      # TODO not importing overlays like this anymore? review how to do overlays
      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs outputs; };
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
            nixos-generators.nixosModules.all-formats # try nix build ~/.setup#nixosConfigurations.twilightrealm.config.formats.isa
            home-manager.nixosModules.default
          ];
          specialArgs = {
            inherit inputs outputs;
          };
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

          iso = # to create ISO and bootable usbs
            nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              #system = "x86_64-linux";
              modules = defaultModules ++ [ 
                ./nixos/iso
              ];
            };
        };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # For Non-NixOS
        "yeshey@zoras" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inherit inputs outputs;
          };
          modules = (builtins.attrValues homeManagerModules) ++ [ ./home-manager/home.nix ];
        };

        #"yeshey@nix-on-droid" = home-manager.lib.homeManagerConfiguration {
        #  pkgs = legacyPackages.x86_64-linux;
        #  extraSpecialArgs = { inherit inputs outputs; };
        #  modules = (builtins.attrValues homeManagerModules) ++ [
        #    ./home-manager/nix-on-droid.nix
        #  ];
        #};
      };

      # For remote deployment, use with Ex: `deploy '.#hyrulecastle' --debug-logs --skip-checks`
      # the deploy-rs package is added globally in modules/nixos/mySystem/default.nix
      deploy.nodes =
        let
          mkDeployConfig = hostname: configuration: {
            inherit hostname;
            profiles.system =
              let
                inherit (configuration.config.nixpkgs.hostPlatform) system;
              in
              {
                path = deploy-rs.lib."${system}".activate.nixos configuration;
                sshUser = "yeshey";
                user = "root";
                sshOpts = [ "-t" ];
                magicRollback = true; # Disable because it breaks remote sudo :<
                interactiveSudo = true;
              };
          };
        in
        {
          hyrulecastle = mkDeployConfig "192.168.1.109" self.nixosConfigurations.hyrulecastle;
          kakariko = mkDeployConfig "kakariko.lan" self.nixosConfigurations.kakariko;
          skyloft = mkDeployConfig "143.47.53.175" self.nixosConfigurations.skyloft;
        };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
