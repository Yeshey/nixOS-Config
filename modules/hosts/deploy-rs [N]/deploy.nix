# modules/hosts/deploy.nix
{ inputs, lib, ... }:
let
  mkNode = name: hostname: {
    inherit hostname;
    sshUser = "root";
    profiles.system =
      let
        cfg = inputs.self.nixosConfigurations.${name};
        targetSystem = cfg.config.nixpkgs.hostPlatform.system;
      in
      {
        user = "root";
        path = inputs.deploy-rs.lib.${targetSystem}.activate.nixos cfg;
      };
  };
in
{
  flake.deploy.nodes = {
    onikao  = mkNode "onikao"  "100.74.87.65";
    skyloft = mkNode "skyloft" "143.47.53.175";
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