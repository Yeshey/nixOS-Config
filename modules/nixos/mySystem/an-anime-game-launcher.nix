# https://github.com/ezKEa/aagl-gtk-on-nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.aagl;
in
{
  imports = [ inputs.aagl.nixosModules.default ];

  options.mySystem.aagl = with lib; {
    enable = mkEnableOption "aagl";
  };

  config = { 
    # nix.settings = inputs.aagl.nixConfig; # Set up Cachix
    programs.anime-game-launcher.enable = true; # Genshin Impact Adds launcher and /etc/hosts rules
    # programs.anime-games-launcher.enable = true; # all others, but not working?
    #programs.honkers-railway-launcher.enable = true;
    #programs.honkers-launcher.enable = true;
    #programs.wavey-launcher.enable = true;
    #programs.sleepy-launcher.enable = true;
  };
}
