{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.nh;
in
{
  options.myHome.nh = with lib; {
    enable = mkEnableOption "nh";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable)  {

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 2d --keep 3";
      flake = "/home/yeshey/.setup";
    };

    # Home Manager Configuration
    home.packages = with pkgs; [
      nix-output-monitor
    ];
    programs.bash.enable = true; # makes work in bash
    programs.zsh.enable = true;
    home.shellAliases = {
      sudo = "sudo "; # makes aliases work even with sudo behind
      # New-style nix commands with nom wrapper
      "nix build" = "${pkgs.nix-output-monitor}/bin/nom build";
      "nix shell" = "${pkgs.nix-output-monitor}/bin/nom shell";
      "nix develop" = "${pkgs.nix-output-monitor}/bin/nom develop";
      # Old-style nix commands with nom wrapper
      "nix-build" = "${pkgs.nix-output-monitor}/bin/nom-build";
      "nix-shell" = "${pkgs.nix-output-monitor}/bin/nom-shell";
    };

  };
}
