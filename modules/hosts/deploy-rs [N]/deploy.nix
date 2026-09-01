# modules/hosts/deploy.nix
# deply with `nix run .#deploy-rs -- .#onikao --auto-rollback true --magic-rollback true --skip-checks`
# if stuck with the ssh connection but no internet, you can still rollback like this:
# `nix-env --list-generations --profile /nix/var/nix/profiles/system`
# /nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch
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
        remoteBuild = true;
      };
    };

    skyloft = {
      hostname = "143.47.53.175";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
          inputs.self.nixosConfigurations.skyloft;
        remoteBuild = true;
      };
    };
  };

  perSystem = { system, ... }: {
    apps.deploy-rs = {
      type = "app";
      program = "${inputs.deploy-rs.packages.${system}.deploy-rs}/bin/deploy";
      meta.description = "Deploy NixOS configs with deploy-rs";
    };
    checks = inputs.deploy-rs.lib.${system}.deployChecks inputs.self.deploy;
  };
}