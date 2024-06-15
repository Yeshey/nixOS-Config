{
  inputs,
  config,
  lib,
  pkgs,
  cfgSystem,
  ...
}:
let
  cfg = config.myHome.xdgPersonalFilesOrganization;
in
{
  options.myHome.xdgPersonalFilesOrganization = with lib; {
    enable = mkEnableOption "xdgPersonalFilesOrganization";
  };

  config = lib.mkIf cfg.enable {

    xdg = {
      # for favourits in nautilus
      enable = lib.mkDefault true;
      userDirs = {
        enable = lib.mkDefault true;
        createDirectories = lib.mkDefault true;
        # desktop = lib.mkDefault "${config.home.homeDirectory}/Pulpit";
        documents = lib.mkDefault "${cfgSystem.mySystem.dataStoragePath}/PersonalFiles/";
        download = lib.mkDefault "${cfgSystem.mySystem.dataStoragePath}/Downloads/";
        music = lib.mkDefault "${cfgSystem.mySystem.dataStoragePath}/PersonalFiles/Timeless/Music/";
        # pictures = lib.mkDefault "${config.home.homeDirectory}/Obrazy";
        # videos = lib.mkDefault "${config.home.homeDirectory}/Wideo";
        # templates = lib.mkDefault "${config.home.homeDirectory}/Szablony";
        # publicShare = lib.mkDefault "${config.home.homeDirectory}/Publiczny";
      };
    };

  };
}