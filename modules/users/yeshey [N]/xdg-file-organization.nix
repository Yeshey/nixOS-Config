
{
  flake.modules.homeManager.yeshey =
  { config, lib, ... }:
  let
    dataPath = config.yeshey.dataStoragePath;
  in {
    xdg = {
      enable = true;
      userDirs = {
        enable = true;
        createDirectories = true;
        
        # Uses the storage path defined in the host
        documents = lib.mkDefault "${dataPath}/PersonalFiles";
        download  = lib.mkDefault "${dataPath}/Downloads";
        music     = lib.mkDefault "${dataPath}/PersonalFiles/Timeless/Music";
        
        # Explicitly setting these to home to avoid KDE/Gnome default pollution
        desktop   = lib.mkDefault "${config.home.homeDirectory}/Desktop";
        pictures  = lib.mkDefault "${config.home.homeDirectory}/Pictures";
        videos    = lib.mkDefault "${config.home.homeDirectory}/Videos";
      };
    };
  };
}