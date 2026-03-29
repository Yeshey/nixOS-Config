{
  flake.modules.nixos.starship = 
    {
      programs.starship.enable = true;
    };

  flake.modules.homeManager.starship =
    { ... }:
    {
      programs.starship = {
        enable = true;
        # settings = pkgs.lib.importTOML ./pinage404.toml; 
      };
    };

}
