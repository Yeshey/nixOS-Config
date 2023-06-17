{ lib, inputs, system, home-manager, user, location, nixos-hardware, nixos-nvidia-vgpu, ... }:

{
  laptop = let 
    host = "laptop";
    dataStoragePath = "/mnt/DataDisk";
  in
   lib.nixosSystem {                           # Desktop profile
    inherit system;
    specialArgs = { inherit user location inputs host dataStoragePath; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./desktop
      ./configuration.nix
      nixos-nvidia-vgpu.nixosModules.nvidia-vgpu

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host dataStoragePath; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./desktop/home.nix)];
        };
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
      ./configuration.nix
      nixos-hardware.nixosModules.microsoft-surface-common # microsoft-surface-pro-intel

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host dataStoragePath; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./surface/home.nix)];
        };
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
      ./configuration.nix

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host dataStoragePath; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./vm/home.nix)];
        };
      }
    ];
  };

/*
  vm = lib.nixosSystem {                               # VM profile
    inherit system;
    specialArgs = { inherit user inputs; };
    modules = [
      ./vm
      ./configuration.nix

      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user; }; 
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./vm/home.nix)];
        };
      }
    ];
  };
*/
}
