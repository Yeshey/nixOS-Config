# base config generated with `nix flake init -t github:misterio77/nix-starter-config#standard`
{
  description = "Hyrule";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    #nixpkgs.url = "github:NixOS/nixpkgs/c16961fda203155a314b0c75c13961c29e9ea7b0";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
    #nixos-nvidia-vgpu = {
    #  url = "github:Yeshey/nixos-nvidia-vgpu/535.129";
      # inputs.nixpkgs.follows = "nixpkgs";
    #};

    nvidia-vgpu-nixos.url = "github:mrzenc/nvidia-vgpu-nixos";
    fastapi-dls-nixos = {
      url = "github:mrzenc/fastapi-dls-nixos";
      # use nixpkgs provided by system to save some space
      # do not use this in case of problems
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-minecraft = {
      #url = "github:Infinidoge/nix-minecraft";
      #url = "github:Faeranne/nix-minecraft"; # has forge support
      url = "github:Yeshey/nix-minecraft";
      #type = "path";
      #path = "/home/yeshey/Downloads/mynixmc/";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-luanti = {
      #inputs.nixpkgs.follows = "nixpkgs-unstable";
      url = "github:lomenzel/nix-luanti";
    };

    #nixos-nvidia-vgpu = { # sudo nixos-rebuild --flake ~/.setup#laptop switch --update-input nixos-nvidia-vgpu --impure
    #  type = "path";
    #  path = "/mnt/DataDisk/PersonalFiles/2023/Projects/Programming/nixos-nvidia-vgpu_nixOS/";
      # inputs.nixpkgs.follows = "nixpkgs";
    #};

    #learnWithT = {
    #  url = "git+ssh://git@github.com/Yeshey/learnWithT.git?ref=main"; # fr my private repo
    #  inputs.nixpkgs.follows = "nixpkgs-unstable";
    #};
    # learnWithT = {
    #   type = "path";
    #   path = "/mnt/DataDisk/PersonalFiles/2024/Projects/Programming/learnWithT/";
    # };

    impermanence.url = "github:nix-community/impermanence";
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

    # Add the nix-on-droid input here
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    #box64-binfmt = {
      # inputs.nixpkgs.follows = "nixpkgs";
      #url = "github:Yeshey/box64-binfmt/main";
    #  type = "path";
    #  path = "/home/yeshey/PersonalFiles/2025/Projects/box64-binfmt/";
    #};

    /*
    wolf = {
      #url = "github:games-on-whales/wolf/dev-nix";
      type = "path";
      path = "/mnt/DataDisk/PersonalFiles/2023/Projects/Programming/nixos-nvidia-vgpu_nixOS/";
      #inputs.nixpkgs.follows = "nixpkgs";
      #inputs.home-manager.follows = "home-manager";
    };
    */
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

    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # using the flatpak
    #aagl = {
    #  url = "github:ezKEa/aagl-gtk-on-nix";
    #  # Or, if you follow Nixkgs release 25.05:
    #  # aagl.url = "github:ezKEa/aagl-gtk-on-nix/release-25.05";
    #  inputs.nixpkgs.follows = "nixpkgs"; # Name of nixpkgs input you want to use
    #};
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixos-hardware,
    home-manager,
    nix-on-droid,
    agenix,
    nixvim,
    nvix,
    deploy-rs,
    stylix,
    plasma-manager,
    nurpkgs,
    hyprland-plugins,
    nvidia-vgpu-nixos,
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
        config.allowUnfree = true;
      }
    );
  in
  rec {
    packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
    formatter = forEachSystem (pkgs: pkgs.nixfmt-rfc-style);
    devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });

    overlays = import ./overlays { inherit inputs outputs; };

    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    nixosConfigurations = {
      hyrulecastle = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
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
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
          nixos-generators.nixosModules.all-formats
          home-manager.nixosModules.default
          ./nixos/skyloft
        ];
      };
      twilightrealm = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
          nixos-generators.nixosModules.all-formats
          home-manager.nixosModules.default
          ./nixos/twilightrealm
        ];
      };
      iso = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues nixosModules) ++ [
          nixos-generators.nixosModules.all-formats
          home-manager.nixosModules.default
          ./nixos/iso
        ];
      };
    };

    homeConfigurations = {
      "yeshey" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
        modules = (builtins.attrValues homeManagerModules) ++ [ ./home-manager/home.nix ];
      };
    };

    myCustomModule = inputs: outputs: {
      _module.args = {
        inherit inputs outputs;
      };
      imports = [ 
        ./nixos/nix-on-droid/default.nix
      ];
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

    deploy.nodes = {
      hyrulecastle = {
        hostname = "hyrulecastle";
        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hyrulecastle;
          sshUser = "yeshey";
          user = "root";
          sshOpts = [ "-t" ];
          magicRollback = true;
          interactiveSudo = true;
        };
      };
      kakariko = {
        hostname = "kakariko";
        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.kakariko;
          sshUser = "yeshey";
          user = "root";
          sshOpts = [ "-t" ];
          magicRollback = true;
          interactiveSudo = true;
        };
      };
      skyloft = {
        hostname = "oracle";
        profiles.system = {
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.skyloft;
          sshUser = "yeshey";
          user = "root";
          sshOpts = [ "-t" ];
          magicRollback = true;
          interactiveSudo = true;
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}


