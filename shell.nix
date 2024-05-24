# Shell for bootstrapping flake-enabled nix and home-manager
{pkgs ? import <nixpkgs> {}, ...}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations";
    nativeBuildInputs = with pkgs; [
      nix
      home-manager
      git

      ssh-to-age
      gnupg
      age
    ];
  };
}
