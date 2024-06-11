{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.freeGames;
in
{
  options.toHost.freeGames = {
    enable = (lib.mkEnableOption "freeGames");
  };

  config = lib.mkIf cfg.enable {

    # currently has epic games captcha problem, and will infinitly retry because of it, so it's turned off

    # journalctl -fu podman-free_games_claimer.service
    # volume: /var/lib/containers/storage/volumes/fgc/_data/
    #run with root: rm -r /var/lib/containers/storage/volumes/fgc/_data/browser/* && rsync -avz /home/yeshey/.mozilla/firefox/yeshey/* /var/lib/containers/storage/volumes/fgc/_data/browser/ && chown -R root:root /var/lib/containers/storage/volumes/fgc/_data/browser
    # verboewser: http://localhost:6080
    # Enable Podman and its service
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.containers = {
      free_games_claimer = {
        image = "ghcr.io/vogler/free-games-claimer";
        #alwaysPull = true;
        volumes = [
          "fgc:/fgc/data"
        ];
        ports = [ "6080:6080" ];
        autoStart = true;
        extraOptions = [ "--rm" "-it" "--pull=always" ];
        environmentFiles = [
          "${config.age.secrets.free_games.path}"
        ];
      };
    };
    
  };
}
