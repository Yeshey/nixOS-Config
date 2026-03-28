{ inputs, ... }:
{
  flake.modules.nixos.i2p = {
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.i2p
    ];

    services.i2p.enable = true;
  };

  flake.modules.homeManager.i2p =
    { pkgs, config, lib, ... }:
    {
      # requires programs.firefox to already be configured — i2p adds a profile on top
      programs.firefox.profiles.i2p = {
        id = 1;
        name = "i2p";
        # inherit extensions and search from your main profile by importing common-conf,
        # but i2p overrides the proxy settings
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          privacy-badger
          bitwarden
          languagetool
          darkreader
        ];
        search = {
          force = true;
          default = "google";
        };
        settings = {
          "general.smoothScroll"                = true;
          "general.autoScroll"                  = true;
          "browser.shell.checkDefaultBrowser"   = false;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.contentblocking.category"    = "strict";
          "dom.security.https_only_mode"        = true;
          "doh-rollout.disable-heuristics"      = true;
          "network.trr.mode"                    = 3;
          # i2p proxy — other sites won't work through this profile
          "media.peerconnection.ice.proxy_only" = true;
          "network.proxy.http"                  = "127.0.0.1";
          "network.proxy.http_port"             = 4444;
          "network.proxy.no_proxies_on"         = "localhost, 127.0.0.1";
          "network.proxy.ssl"                   = "127.0.0.1";
          "network.proxy.ssl_port"              = 4444;
          "network.proxy.type"                  = 1;
        };
        extraConfig = ''
          user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
          user_pref("media.ffmpeg.vaapi.enabled", true);
        '';
        bookmarks = {
          force = true;
          settings = [{
            name = "Bookmarks";
            toolbar = true;
            bookmarks = [{
              name = "i2p Router Console";
              url  = "http://127.0.0.1:7657/welcome";
            }];
          }];
        };
      };

      home.packages = [
        (pkgs.makeDesktopItem {
          name        = "firefox-i2p";
          desktopName = "Firefox (i2p)";
          genericName = "i2p Browser Profile";
          exec        = ''firefox -no-remote -P "i2p" %U http://127.0.0.1:7657/welcome'';
          icon        = "firefox";
          categories  = [ "Network" "WebBrowser" ];
          mimeTypes   = [
            "text/html"
            "text/xml"
            "application/xhtml+xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
          ];
        })
      ];
    };
}