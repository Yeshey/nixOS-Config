{
  # sops-nix: Atomic secret provisioning for NixOS based on sops
  # https://github.com/Mic92/sops-nix

  flake-file.inputs = {
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}