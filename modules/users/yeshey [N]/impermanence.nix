{
  inputs,
  ...
}:
{
  flake.modules.homeManager.yeshey =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            "PersonalFiles"
            "Downloads"
            "Music"
            "Pictures"
            "Documents"
            "Videos"
            ".setup"
            ".gnupg"
            ".floorp"
            ".config/rclone"
            ".config/org.restic.browser"
            ".local/share/osu"
            ".local/share/PrismLauncher/instances/MainInstance"
            "Zotero/storage"
            { directory = ".local/share/keyrings"; mode = "0700"; }

            # syncthing
            ".stversions"
            ".stfolder"
          ];
          files = [
            # syncthing
            ".python_history"
          ];
        };
      };
    };
}
