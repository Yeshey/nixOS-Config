{ lib, inputs, system, home-manager, user, location, nixos-hardware, nixos-nvidia-vgpu, nur, ... }:

{
  laptop = let 
    host = "laptop";
    dataStoragePath = "/mnt/DataDisk";
  in
   lib.nixosSystem {                           # Desktop profile
    inherit system;
    specialArgs = { inherit user location inputs host dataStoragePath ; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./laptop
      ./baseConfiguration.nix
      ./configFiles/non-serverConfiguration.nix
      # nur.nixosModules.nur
      #nixos-nvidia-vgpu.nixosModules.nvidia-vgpu

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host dataStoragePath ; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./baseHome.nix)] ++ [(import ./configFiles/homeApps.nix)] ++ [(import ./laptop/home.nix)];
        };
        nixpkgs.overlays = [ nur.overlay ]; # To use nur packages in home manager (https://www.reddit.com/r/NixOS/comments/r9544v/comment/hnbw3df/?utm_source=share&utm_medium=web2x&context=3)
      }
    ];
  };

  surface = let 
    host = "surface"; 
    dataStoragePath = "/mnt/ntfsMicroSD-DataDisk"; 
  in lib.nixosSystem {                           # Surface profile
    inherit system;
    specialArgs = { inherit user location inputs host dataStoragePath; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./surface
      ./baseConfiguration.nix
      ./configFiles/non-serverConfiguration.nix
      nixos-hardware.nixosModules.microsoft-surface-pro-intel # Not broken anymore

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host dataStoragePath; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./baseHome.nix)] ++ [(import ./configFiles/homeApps.nix)] ++ [(import ./surface/home.nix)];
        };
        nixpkgs.overlays = [ nur.overlay ]; # To use nur packages in home manager (https://www.reddit.com/r/NixOS/comments/r9544v/comment/hnbw3df/?utm_source=share&utm_medium=web2x&context=3)
      }
    ];
  };

  vm = let 
    host = "vm";
    dataStoragePath = "~/Documents";
  in
   lib.nixosSystem {                           # Desktop profile
    inherit system;
    specialArgs = { inherit user location inputs host dataStoragePath; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./vm
      ./baseConfiguration.nix
      ./configFiles/non-serverConfiguration.nix

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host dataStoragePath; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./baseHome.nix)] ++ [(import ./configFiles/homeApps.nix)] ++ [(import ./vm/home.nix)];
        };
        nixpkgs.overlays = [ nur.overlay ]; # To use nur packages in home manager (https://www.reddit.com/r/NixOS/comments/r9544v/comment/hnbw3df/?utm_source=share&utm_medium=web2x&context=3)
      }
    ];
  };

  arm-oracle = let 
    host = "arm-oracle";
    dataStoragePath = "/home/${user}";
  in
   lib.nixosSystem {                           # Desktop profile
    inherit system;
    specialArgs = { inherit user location inputs host dataStoragePath; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./oracleArmVM
      ./baseConfiguration.nix
      # ./configFiles/non-serverConfiguration.nix

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host dataStoragePath; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./baseHome.nix)] ++ [(import ./oracleArmVM/home.nix)];
        };
        nixpkgs.overlays = [ nur.overlay ]; # To use nur packages in home manager (https://www.reddit.com/r/NixOS/comments/r9544v/comment/hnbw3df/?utm_source=share&utm_medium=web2x&context=3)
      }
    ];
  };


/*
  vm = lib.nixosSystem {                               # VM profile
    inherit system;
    specialArgs = { inherit user inputs; };
    modules = [
      ./vm
      ./baseConfiguration.nix

      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user; }; 
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./vm/home.nix)];
        };
        nixpkgs.overlays = [ nur.overlay ]; # To use nur packages in home manager (https://www.reddit.com/r/NixOS/comments/r9544v/comment/hnbw3df/?utm_source=share&utm_medium=web2x&context=3)
      }
    ];
  };
*/
}
