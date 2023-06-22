{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
    imports = [
        # ...
    ];

  # journalctl -fu openvscode-server.service
  # connect to this server with `ssh -L 9090:localhost:3000 yeshey@130.61.219.132`, and go to http://localhost:9090 in your browser
  # This seems to work:
  # (ssh -L 9090:localhost:3000 -t yeshey@130.61.219.132 "sleep 90" &) && xdg-open http://localhost:9090
  services.openvscode-server = {
    enable = true;
    host = "localhost";
    port = 3000;
    user = "${user}";
    extensionsDir = "/home/${user}/.vscode-oss/extensions";
    withoutConnectionToken = true; # So you don't need to grab the token that it generates here
  };

}
