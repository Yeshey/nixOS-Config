{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.homeApps.firefox;
in
{
  options.myHome.homeApps.firefox = with lib; {
    enable = mkEnableOption "firefox";
    i2pFirefoxProfile = mkOption {
      type = types.bool;
      default = (osConfig.services.i2p.enable or false) || (osConfig.mySystem.i2p.enable or false);
      description = "weather to make a special firefox profile for i2p";
    };
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

    # home.persistence."/persist/home/yeshey" = {
    #   directories = [
    #     ".mozilla"
    #   ];
    #   allowOther = true;
    # };

    programs.firefox = {
      enable = true;
      # Floorp doesn't compile in home manager if I have this here:
      /* package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies = {
          CaptivePortal = false;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DisableFirefoxAccounts = false;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          OfferToSaveLoginsDefault = false;
          PasswordManagerEnabled = false;
          FirefoxHome = {
            Search = true;
            Pocket = false;
            Snippets = false;
            TopSites = false;
            Highlights = false;
          };
          UserMessaging = {
            ExtensionRecommendations = false;
            SkipOnboarding = true;
          };
        };
      };*/
      profiles =
        let
          common-conf = {
            bookmarks = {
              force = true;
              settings = [ ];
            };
            extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
              # You need to activate the extensions manually
              ublock-origin
              privacy-badger
              # https-everywhere
              bitwarden
              # floccus
              # privacy-redirect
              languagetool
              darkreader
              metamask
            ];
            id = 0; # default profile
            name = "${config.home.username}";
            search = {
              force = true;
              default = "google"; # DuckDuckGo
              engines = {
                "Nix Packages" = {
                  urls = [
                    {
                      template = "https://search.nixos.org/packages";
                      params = [
                        {
                          name = "type";
                          value = "packages";
                        }
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@np" ];
                };
                "NixOS Wiki" = {
                  urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
                  icon = "https://nixos.wiki/favicon.png";
                  updateInterval = 24 * 60 * 60 * 1000;
                  definedAliases = [ "@nw" ];
                };
                "wikipedia".metaData.alias = "@wiki";
                #"Google".metaData.hidden = true;
                "amazondotcom-us".metaData.hidden = true;
                "bing".metaData.hidden = true;
                "ebay".metaData.hidden = true;
              };
            };
            settings = {
              # Check /home/yeshey/.mozilla/firefox/<user>/prefs.js to see these settings change
              "general.smoothScroll" = true;
              "general.autoScroll" = true;
              "browser.shell.checkDefaultBrowser" = false;
              "browser.toolbars.bookmarks.visibility" = "always";
              "browser.tabs.firefox-view" = false; # disable firefox feature to see tabs in firefox open in other devices
              "services.sync.prefs.sync.browser.firefox-view.feature-tour" = false;

              "browser.contentblocking.category" = "strict";
              "dom.security.https_only_mode" = true;
              # Enable secure DNS Max protection
              "doh-rollout.disable-heuristics" = true;
              "network.trr.mode" = 3;
            };
            extraConfig = ''
              user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
              user_pref("full-screen-api.ignore-widgets", true);
              user_pref("media.ffmpeg.vaapi.enabled", true);  
              user_pref("media.rdd-vpx.enabled", true);
              user_pref("media.rdd-ffmpeg.enabled", true);
              user_pref("media.av1.enabled", false);
              user_pref("gfx.x11-egl.force-enabled", true);
              user_pref("widget.dmabuf.force-enabled", true);
            '';
            userChrome = ''
              # a css 
            '';
            userContent = ''
              # Here too
            '';
          };
        in
        {
          # to switch profile go to about:profiles
          ${config.home.username} = common-conf;
        } // lib.optionalAttrs cfg.i2pFirefoxProfile {
          i2p =
            common-conf
            // {
              bookmarks = {
                force = true;
                settings = [
                {
                  # does't work?
                  name = "Bookmarks";
                  toolbar = true;
                  bookmarks = [
                    {
                      name = "TPB";
                      keyword = "tpb";
                      url = "https//thepiratebay.org";
                    }
                  ];
                }
              ];};
              id = 1;
              name = "i2p";
              settings = common-conf.settings // {
                # Make i2p work, other sites won't work anymore, (or be very slow?) however
                "media.peerconnection.ice.proxy_only" = true;
                "network.proxy.http" = "127.0.0.1";
                "network.proxy.http_port" = 4444;
                "network.proxy.no_proxies_on" = "localhost, 127.0.0.1";
                "network.proxy.ssl" = "127.0.0.1";
                "network.proxy.ssl_port" = 4444;
                "network.proxy.type" = 1;
              };
            };
        };
    };

    home.packages =
      let
        i2p = pkgs.makeDesktopItem {
          name = "i2p";
          desktopName = "i2p";
          genericName = "i2p";
          exec = ''firefox -no-remote -P "i2p" %U http://127.0.0.1:7657/welcome'';
          icon = "firefox";
          categories = [
            "Network"
            "WebBrowser"
          ];
          mimeTypes = [
            "text/html"
            "text/xml"
            "application/xhtml+xml"
            "application/vnd.mozilla.xul+xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
          ];
        };
      in
      with pkgs;
      lib.mkIf cfg.i2pFirefoxProfile [ i2p ];
  };
}
