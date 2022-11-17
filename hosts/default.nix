{ lib, inputs, system, home-manager, user, location, nixos-hardware, ... }:

{
  laptop = lib.nixosSystem {                           # Desktop profile
    inherit system;
    specialArgs = { inherit user location inputs; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./desktop
      ./configuration.nix

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location; };  # Pass flake variable
        home-manager.users.${user} = {
          imports = [(import ./home.nix)] ++ [(import ./desktop/home.nix)];
        };
      }
    ];
  };

  surface = lib.nixosSystem {                           # Surface profile
    inherit system;
    specialArgs = { inherit user location inputs; };             # Pass flake variable
    modules = [                                         # Modules that are used.
      ./surface
      ./configuration.nix
      # nixos-hardware.nixosModules.microsoft-surface # Broken for now (https://github.com/NixOS/nixos-hardware/issues/504)

      home-manager.nixosModules.home-manager {          # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user location; };  # Pass flake variable
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
