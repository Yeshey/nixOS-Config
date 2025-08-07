{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.nh;
in
{
  options.mySystem.nh = with lib; {
    enable = mkEnableOption "nh";
  };

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = lib.mkIf (config.mySystem.enable && cfg.enable) { 

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 2d --keep 3";
      flake = "/home/yeshey/.setup";
    };

    # NixOS Configuration
    environment.shellAliases = {
      sudo = "sudo "; # makes aliases work even with sudo behind
      # New-style nix commands with nom wrapper
      "nix build" = "${pkgs.nix-output-monitor}/bin/nom build";
      "nix shell" = "${pkgs.nix-output-monitor}/bin/nom shell";
      "nix develop" = "${pkgs.nix-output-monitor}/bin/nom develop";
      # Old-style nix commands with nom wrapper
      "nix-build" = "${pkgs.nix-output-monitor}/bin/nom-build";
      "nix-shell" = "${pkgs.nix-output-monitor}/bin/nom-shell";
    };
    environment.systemPackages = with pkgs; [
      nix-output-monitor
    ];

  };
}
