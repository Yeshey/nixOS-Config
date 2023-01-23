{ lib, inputs, system, home-manager, user, location, nixos-hardware, ... }:

{
  laptop = let 
    host = "laptop"; 
  in
   lib.nixosSystem {                           # Desktop profile
    inherit system;
    specialArgs = { inherit user location inputs host; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./desktop
      ./configuration.nix

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./desktop/home.nix)];
        };
      }
    ];
  };

  surface = let 
    host = "surface"; 
  in lib.nixosSystem {                           # Surface profile
    inherit system;
    specialArgs = { inherit user location inputs host ; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./surface
      ./configuration.nix
      nixos-hardware.nixosModules.microsoft-surface-pro-intel # Not broken anymore

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location host; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./surface/home.nix)];
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
