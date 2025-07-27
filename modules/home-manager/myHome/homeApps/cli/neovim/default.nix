# stole from https://github.com/n3oney/nixus/blob/main/modules/programs/neovim.nix
{ pkgs, lib, config, inputs, ... }:

let
  mkLua = lib.generators.mkLuaInline;
  cfgNeovim = config.myHome.homeApps.cli.neovim;
in
{
  options.myHome.homeApps.cli.neovim = with lib; {
    enable = mkEnableOption "neovim";
  };

  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && config.myHome.homeApps.cli.enable && cfgNeovim.enable) {

    # https://github.com/niksingh710/nvix
    # For Home Manager
    home.packages = with pkgs; [
      # Your nvix package
      (inputs.nvix.packages.${pkgs.system}.full.extend { # Replace `default` with `bare`, `core`, or `full` as needed.
        # Disable avante plugin because it's requiering to setup copilot and I dont know how to do that yet
        plugins.avante.enable = lib.mkForce false; 
      })
      # Development tools for nvix (dont know if I need but there were some errors so)
      gcc
      gnumake
      pkg-config
    ];

  };
}