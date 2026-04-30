{ inputs, ... }:
{
  flake.modules.nixos.nix-index-database = 
    { pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.nixosModules.nix-index ];
      programs.nix-index-database.comma.enable = true;

      environment.systemPackages = [ pkgs.jq ];
    };

  flake.modules.homeManager.nix-index-database =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];
      programs.nix-index-database.comma.enable = true;

      home.packages = [ pkgs.jq ];
    };
}