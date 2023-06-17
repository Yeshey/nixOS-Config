{
  description = "A very basic flake";

  inputs = {
    # Release Notes: https://nixos.org/manual/nixos/stable/release-notes.html
    # sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixpkgs
    # sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixos
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

    #nixos-nvidia-vgpu = { # sudo nixos-rebuild --flake ~/.setup#laptop switch --update-input nixos-nvidia-vgpu --impure
    #  type = "path";
    #  path = "/mnt/DataDisk/PersonalFiles/2023/Projects/Programming/nixos-nvidia-vgpu_nixOS/";
    #};
    nixos-nvidia-vgpu.url = "github:Yeshey/nixos-nvidia-vgpu/master";

    # Specific commit because microsoft Surface keeps breaking. 0fbf27af51a7c9bc68a168fdcd63513c4f100b15 # de3ec80522011e938a55c3964d9e1f8826215796
    nixos-hardware.url = "https://github.com/NixOS/nixos-hardware/archive/30066d1886a111a917f82154ac90167b0042b29d.tar.gz"; # "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "https://github.com/nix-community/home-manager/archive/release-23.05.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, nixos-hardware, nixos-nvidia-vgpu, ...}:
    let
      system = "x86_64-linux";                                # System architecture
      user = "yeshey";
      location = "/home/${user}/.setup"; # "$HOME/.setup"

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;                            # Allow proprietary software
      };

      lib = nixpkgs.lib;
    in {
      nixosConfigurations = (                                 # Location of the available configurations
        import ./hosts {                                      # Imports ./hosts/default.nix
          inherit (nixpkgs) lib;
          inherit inputs user location system home-manager nixos-hardware nixos-nvidia-vgpu;            # Also inherit home-manager so it does not need to be defined here.
        }
      );

      #homeConfigurations = (                                 # Non-NixOS configurations
      #  import ./nix {
      #    inherit (nixpkgs) lib;
      #    inherit inputs nixpkgs home-manager nixgl user;
      #  }
      #);

    };

}
