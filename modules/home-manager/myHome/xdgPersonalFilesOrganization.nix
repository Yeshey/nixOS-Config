{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = config.myHome.xdgPersonalFilesOrganization;
in
{
  options.myHome.xdgPersonalFilesOrganization = with lib; {
    enable = mkEnableOption "xdgPersonalFilesOrganization";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    xdg = {
      # for favourits in nautilus
      enable = lib.mkOverride 1010 true;
      userDirs = {
        enable = lib.mkOverride 1010 true;
        createDirectories = lib.mkOverride 1010 true;
        # desktop = lib.mkOverride 1010 "${config.home.homeDirectory}/Pulpit";
        documents = lib.mkOverride 1010 "${config.myHome.dataStoragePath}/PersonalFiles/";
        download = lib.mkOverride 1010 "${config.myHome.dataStoragePath}/Downloads/";
        music = lib.mkOverride 1010 "${config.myHome.dataStoragePath}/PersonalFiles/Timeless/Music/";
        # pictures = lib.mkOverride 1010 "${config.home.homeDirectory}/Obrazy";
        # videos = lib.mkOverride 1010 "${config.home.homeDirectory}/Wideo";
        # templates = lib.mkOverride 1010 "${config.home.homeDirectory}/Szablony";
        # publicShare = lib.mkOverride 1010 "${config.home.homeDirectory}/Publiczny";
      };
    };

  };
}