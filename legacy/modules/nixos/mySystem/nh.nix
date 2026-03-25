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

    security.sudo.extraConfig = ''
      Defaults env_keep += "NH_FLAKE NH_HOSTNAME"
    ''; # So it preserves the location of the flake variable when you do "sudo nh os switch" from yeshey user.

    programs.nh = {
      enable = true;
      flake = "/home/yeshey/.setup";
    };

    # NixOS Configuration
    environment.shellAliases = {
      sudo = "sudo "; # makes aliases work even with sudo behind
      # Old-style nix commands with nom wrapper
      "nix-build" = "${pkgs.nix-output-monitor}/bin/nom-build";
      "nix-shell" = "${pkgs.nix-output-monitor}/bin/nom-shell";
    };
    environment.systemPackages = with pkgs; [
      nix-output-monitor
    ];

  };
}
