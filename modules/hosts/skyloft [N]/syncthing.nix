{
  flake.modules.homeManager.skyloft = {
    services.syncthing = {
      guiAddress = "0.0.0.0:8384";
    };
  };

  flake.modules.nixos.skyloft = { lib, ... }: {
    services.syncthing = {
      guiAddress = "0.0.0.0:8384";
      # I don't want to sync everything anymore
      # settings = {
      #   folders = {
      #     "PersonalFiles" = {
      #       ignorePatterns = lib.mkForce (
      #         [
      #           "/Timeless/Syncthing/WhatsAppMovies"
      #           "/Timeless/Syncthing/WhatsAppPictures"
      #           "/Timeless/Syncthing/A70Camera"
      #         ] ++ (import (builtins.toPath "${./../..}/users/yeshey [Nn]/syncthing [N]/global-excludes.nix-data"))
      #       );
      #     };
      #   };
      # };
    };
  };
}