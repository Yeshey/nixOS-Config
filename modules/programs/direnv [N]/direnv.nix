{
  flake.modules.nixos.direnv = 
    {
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
        settings = {
          global = {
            hide_env_diff = true;
          };
        };
      };
    };

  flake.modules.homeManager.direnv =
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        config = {
          global = {
            hide_env_diff = true;
          };
        };
      };
    };
}