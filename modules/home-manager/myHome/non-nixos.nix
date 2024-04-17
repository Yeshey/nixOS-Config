{ inputs, outputs, config, lib, pkgs, ... }:

let
  cfg = config.myHome.nonNixos;
  substituters = {
    cachenixosorg = {
      url = "https://cache.nixos.org";
      key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    };
    cachethalheimio = {
      url = "https://cache.thalheim.io";
      key = "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=";
    };
    numtidecachixorg = {
      url = "https://numtide.cachix.org";
      key = "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=";
    };
    hydranixosorg = {
      url = "https://hydra.nixos.org";
      key = "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=";
    };
    nrdxpcachixorg = {
      url = "https://nrdxp.cachix.org";
      key = "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4=";
    };
    nixcommunitycachixorg = {
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    };
  };
in
{
  options.myHome.nonNixos = with lib; {
    enable = mkEnableOption "nonNixos";
    nix.substituters = mkOption {
      type = types.listOf types.str;
      default = builtins.attrValues substituters; # by default use all # TODO check if works, 
    };
  };
  config = lib.mkIf cfg.enable {
    home.sessionPath = [ "$HOME/.local/bin" ];
    home.packages = [
      pkgs.hostname
      config.nix.package # This must be here, enable option below does not ensure that nix is available in path
      pkgs.nixgl.auto.nixGLDefault
    ];

    nixpkgs.overlays = builtins.attrValues outputs.overlays;
    nixpkgs.config.allowUnfree = true;
    nix = {
      enable = true;
      package = pkgs.nix;
      extraOptions = ''
        experimental-features = nix-command flakes
        !include ./extra.conf
      '';
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      settings = lib.mkMerge [
        {
          nix-path = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
          substituters = map (x: substituters.${x}.url) cfg.nix.substituters;
          trusted-public-keys = map (x: substituters.${x}.key) cfg.nix.substituters;
        }
        {
          trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
          substituters = lib.mkAfter [ "https://cache.nixos.org/" ];
        }
      ];
    };
    programs.home-manager.enable = true;
  };
}
