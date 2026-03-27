{ inputs, ... }:
{
  flake.modules.nixos.speedtest-tracker =
    { pkgs, config, ... }:
    {
      imports = [
        # module definition comes from unstable
        "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/speedtest-tracker.nix" # TODO, remove on 26.05
      ];

      services.speedtest-tracker = {
        enable      = true;
        enableNginx = true;
        virtualHost = "localhost";
        # use the unstable package to match the module
        package  = pkgs.unstable.speedtest-tracker;
        settings = {
          DB_CONNECTION    = "sqlite";
          DISPLAY_TIMEZONE = "Europe/Lisbon";
          APP_TIMEZONE     = "Europe/Lisbon";
          AUTH             = "false";
          APP_KEY_FILE = pkgs.writeText "app-key" "base64:YhS9gRsNxUpHjyCg+TY0bjB9DIm24BeWpSA4p7f7pSA=";
        }; 
      };

      services.nginx.virtualHosts."localhost".listen = [{
        addr = "0.0.0.0";
        port = 8881;
      }];

      environment.systemPackages = [
        (pkgs.makeDesktopItem {
          name        = "speedtest-tracker";
          desktopName = "Speedtest Tracker";
          genericName = "Internet Speed Monitor";
          exec        = ''xdg-open "http://localhost:8881/admin"'';
          icon        = "network-transmit-receive";
          categories  = [ "Network" "Monitor" ];
          mimeTypes   = [ "text/html" "text/xml" "application/xhtml+xml" ];
        })
      ];
    };
}