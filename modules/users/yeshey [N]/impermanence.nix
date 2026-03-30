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
            { directory = ".local/share/keyrings"; mode = "0700"; }

            # syncthing
            ".stversions"
            ".stfolder"
          ];
          files = [
            # syncthing
            ".stignore"
            ".python_history"
          ];
        };
      };
    };
}
