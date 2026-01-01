# base config generated with `nix flake init -t github:misterio77/nix-starter-config#standard`
{
  description = "Hyrule";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    #nixpkgs.url = "github:NixOS/nixpkgs/c16961fda203155a314b0c75c13961c29e9ea7b0";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:8bitbuddhist/nixos-hardware/surface-kernel-6.18";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
        url = "github:nix-community/nixvim";
        # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
        inputs.nixpkgs.follows = "nixpkgs";
    };
    nvix.url = "github:niksingh710/nvix";
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
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
    vgpu4nixos = {
      url = "github:mrzenc/vgpu4nixos";
    };
    fastapi-dls-nixos = {
      url = "github:mrzenc/fastapi-dls-nixos/v1.x";
      # use nixpkgs provided by system to save some space
      # do not use this in case of problems
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      #url = "github:Infinidoge/nix-minecraft";
      url = "github:Yeshey/nix-minecraft";
      #type = "path";
      #path = "/home/yeshey/Downloads/nm/";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-luanti = {
      url = "git+https://git.menzel.lol/leonard/nix-luanti";
      #inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    impermanence.url = "github:nix-community/impermanence/home-manager-v2";
    # deploy-rs = {
    #   url = "github:serokell/deploy-rs";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
    # Add the nix-on-droid input here
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # box64-binfmt = {
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   url = "github:Yeshey/box64-binfmt/main";
    #   #type = "path";
    #   #path = "/home/yeshey/PersonalFiles/2025/Projects/box64-binfmt/";
    # };
    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixos-hardware,
    nix-index-database,
    home-manager,
    nix-on-droid,
    agenix,
    nixvim,
    nvix,
    # deploy-rs,
    stylix,
    plasma-manager,
    nurpkgs,
    hyprland-plugins,
    vgpu4nixos,
    #learnWithT,
    fastapi-dls-nixos,
    nixos-generators,
    impermanence,
    #box64-binfmt,
    #wolf,
    # lanzaboote,
    nix-snapd,
    nix-minecraft,
    nix-luanti,
    #aagl,
    nix-flatpak,
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
        config = {
          allowUnfree            = true;
          allowUnsupportedSystem = true;
          allowBroken            = true;
          # permittedInsecurePackages = [ ];  # uncomment if you ever need it
        };
      }
    );
  in
  rec {
    packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
    formatter = forEachSystem (pkgs: pkgs.nixfmt-rfc-style);
    devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });

    overlays = import ./overlays { inherit inputs outputs; };

    nixosModules = import ./modules/nixos;
    homeModules = import ./modules/home-manager;

    nixosConfigurations = {
      hyrulecastle = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
          inputs.nixos-facter-modules.nixosModules.facter { config.facter.reportPath = ./nixos/hyrulecastle/facter.json; }
          nixos-generators.nixosModules.all-formats
          home-manager.nixosModules.default
          ./nixos/hyrulecastle
        ];
      };
      kakariko = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
          nixos-generators.nixosModules.all-formats
          home-manager.nixosModules.default
          ./nixos/kakariko
        ];
      };
      skyloft = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
          inputs.nixos-facter-modules.nixosModules.facter { config.facter.reportPath = ./nixos/skyloft/facter.json; }
          nixos-generators.nixosModules.all-formats
          home-manager.nixosModules.default
          ./nixos/skyloft
        ];
      };
      twilightrealm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
          nixos-generators.nixosModules.all-formats
          home-manager.nixosModules.default
          ./nixos/twilightrealm
        ];
      };
    };

    homeConfigurations = {
      "yeshey" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues homeModules) ++ [ ./home-manager/home.nix ];
      };
    };

    nixOnDroidConfigurations.nix-on-droid = nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-linux";
        config.allowUnfree = true;  # Add this line
      };
      modules = [
        #(myCustomModule inputs outputs)
        ./nixos/nix-on-droid/default.nix
      ];
    };

    # deploy.nodes = {
    #   hyrulecastle = {
    #     hostname = "hyrulecastle";
    #     profiles.system = {
    #       path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hyrulecastle;
    #       sshUser = "yeshey";
    #       user = "root";
    #       sshOpts = [ "-t" ];
    #       magicRollback = true;
    #       interactiveSudo = true;
    #     };
    #   };
    #   kakariko = {
    #     hostname = "kakariko";
    #     profiles.system = {
    #       path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.kakariko;
    #       sshUser = "yeshey";
    #       user = "root";
    #       sshOpts = [ "-t" ];
    #       magicRollback = true;
    #       interactiveSudo = true;
    #     };
    #   };
    #   skyloft = {
    #     hostname = "oracle";
    #     profiles.system = {
    #       path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.skyloft;
    #       sshUser = "yeshey";
    #       user = "root";
    #       sshOpts = [ "-t" ];
    #       magicRollback = true;
    #       interactiveSudo = true;
    #     };
    #   };
    # };

    # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
