{ inputs, ... }:
{
  flake.modules.homeManager.standalone-hm =
    { lib, pkgs, config, ... }:
    {
      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) config;
            system = pkgs.stdenv.hostPlatform.system;
          };
        })
        (final: prev: {
          nur = import inputs.nurpkgs {
            nurpkgs = prev;
            pkgs = prev;
          };
        })
      ];

      # Ensure nix is in PATH — needed when HM manages nix on non-NixOS
      home.packages = [
        pkgs.hostname
        config.nix.package
      ];

      home.sessionPath = [ "$HOME/.local/bin" ];

      nixpkgs.config.allowUnfree = true;

      nix = {
        enable  = true;
        package = pkgs.nix;
        # allows per-machine extra config without touching the main config
        extraOptions = ''
          !include ./extra.conf
        '';
        registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
        settings = {
          nix-path = lib.mapAttrsToList
            (key: value: "${key}=${value.to.path}")
            config.nix.registry;
        };
      };

      programs.home-manager.enable = true;

      programs.zsh.shellAliases = {
        update = "home-manager switch --flake ~/.setup#yeshey";
      };
    };
}