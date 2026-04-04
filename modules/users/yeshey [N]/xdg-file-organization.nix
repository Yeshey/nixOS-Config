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
        
        documents = lib.mkDefault "/home/yeshey/PersonalFiles";
        download  = lib.mkDefault "${dataPath}/Downloads";
        music     = lib.mkDefault "${dataPath}/PersonalFiles/Timeless/Music";
        
        desktop   = lib.mkDefault "${config.home.homeDirectory}/Desktop";
        pictures  = lib.mkDefault "${config.home.homeDirectory}/Pictures";
        videos    = lib.mkDefault "${config.home.homeDirectory}/Videos";
      };
    };

    gtk = {
      enable = true;
      gtk3.bookmarks = [
        "file://${config.xdg.userDirs.documents} Documents"
        "file://${config.xdg.userDirs.download} Downloads"
        "file://${config.xdg.userDirs.music} Music"
        "file://${config.xdg.userDirs.pictures} Pictures"
        "file://${config.xdg.userDirs.videos} Videos"
        "sftp://hyrulecastle Hyrule Castle"
        "sftp://kakariko Kakariko"
        "sftp://oracle Oracle"
      ];
    };
  };
}