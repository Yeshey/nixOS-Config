{ inputs, ... }:
let
  devTools = pkgs: with pkgs; [ 
    lazygit fd git imagemagick ghostscript ripgrep
  ];

  # https://github.com/niksingh710/nvix
  # Replace `core` with `bare` or `full` as needed
  nvix = pkgs: lib:
    inputs.nvix.packages.${pkgs.stdenv.hostPlatform.system}.bare.extend {
      plugins.avante.enable = lib.mkForce false;
      plugins.obsidian.enable = lib.mkForce false;
    };

  packages = pkgs: lib: [ (nvix pkgs lib) ] ++ devTools pkgs;
in
{
  flake.modules.nixos.nvix = { pkgs, lib, ... }: {
    environment.systemPackages = packages pkgs lib;
  };

  flake.modules.darwin.nvix = { pkgs, lib, ... }: {
    environment.systemPackages = packages pkgs lib;
  };

  flake.modules.homeManager.nvix = { pkgs, lib, ... }: {
    home.packages = packages pkgs lib;
  };
}