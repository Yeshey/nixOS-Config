{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {

    nixosConfigurations.container = nixpkgs.lib.nixosSystem {
      #system = "armv7l-linux";
      system = "aarch64-linux";
      modules = [
        {
          services.nginx.enable = true;

          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

          system.stateVersion = "24.05";

          boot.isContainer = true;
          networking.useDHCP = false;
          networking.firewall.allowedTCPPorts = [ 80 ];
          networking.hostName = "nginx";
        }
      ];
    };

  };
}
