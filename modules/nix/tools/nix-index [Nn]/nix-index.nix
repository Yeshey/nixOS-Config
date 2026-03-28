{
  flake.modules.nixos.nix-index = {
    programs.nix-index.enable = true;
  };

  flake.modules.homeManager.nix-index = {
    programs.nix-index.enable = true;
  };
}