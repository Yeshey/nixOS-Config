# modules/hosts/deploy.nix
{ inputs, ... }:
{
  flake.deploy.nodes = {
    onikao = {
      hostname = "100.74.87.65"; # tailscale IP
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
          inputs.self.nixosConfigurations.onikao;
      };
    };

    skyloft = {
      hostname = "143.47.53.175";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
          inputs.self.nixosConfigurations.skyloft;
      };
    };
  };

  perSystem = { system, ... }: {
    apps.deploy-rs = {
      type = "app";
      program = "${inputs.deploy-rs.packages.${system}.deploy-rs}/bin/deploy";
    };
    checks = inputs.deploy-rs.lib.${system}.deployChecks inputs.self.deploy;
  };
}