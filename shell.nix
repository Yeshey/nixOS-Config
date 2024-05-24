# Shell for bootstrapping flake-enabled nix and home-manager
# NOTE: if you use nix-shell, you must not run nixos-install inside the nix-shell! (maybe? )
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
