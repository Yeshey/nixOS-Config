{
  flake.modules.nixos.hyrulecastle = { lib, ... }: {
    services.syncthing = {
      settings = {
        folders = {
          "PersonalFiles" = {
            type = "sendonly";
            # I don't want to sync everything anymore
            # ignorePatterns = lib.mkForce (
            #   [
            #     "/Timeless/Syncthing/WhatsAppMovies"
            #     "/Timeless/Syncthing/WhatsAppPictures"
            #     "/Timeless/Syncthing/A70Camera"
            #   ] ++ (import (builtins.toPath "${./../..}/users/yeshey [Nn]/syncthing [N]/global-excludes.nix-data"))
            # );
          };
        };
      };
    };
  };
}