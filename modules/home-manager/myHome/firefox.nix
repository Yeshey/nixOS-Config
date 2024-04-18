{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.firefox;
  user = "yeshey";
in {
  options.myHome.firefox = with lib; {
    enable = mkEnableOption "firefox";
  };

  config = lib.mkIf cfg.enable {

    # TODO can you fix this?
    # https://discourse.nixos.org/t/help-setting-up-firefox-with-home-manager/23333
    programs.firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
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
      };
      profiles = let
        common-conf = {
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [ # You need to activate the extensions manually
              ublock-origin
              privacy-badger
              # https-everywhere
              bitwarden
              # floccus
              # privacy-redirect
              privacy-badger
              languagetool
              darkreader
              metamask
          ];
          id = 0; # default profile
          name = "${user}";
          search = {
              force = true;
              default = "Google"; #DuckDuckGo
              engines = {
                  "Nix Packages" = {
                      urls = [{
                          template = "https://search.nixos.org/packages";
                          params = [
                              { name = "type"; value = "packages"; }
                              { name = "query"; value = "{searchTerms}"; }
                          ];
                      }];
                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@np" ];
                  };
                  "NixOS Wiki" = {
                      urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
                      iconUpdateURL = "https://nixos.wiki/favicon.png";
                      updateInterval = 24 * 60 * 60 * 1000;
                      definedAliases = [ "@nw" ];
                  };
                  "Wikipedia (en)".metaData.alias = "@wiki";
                  #"Google".metaData.hidden = true;
                  "Amazon.com".metaData.hidden = true;
                  "Bing".metaData.hidden = true;
                  "eBay".metaData.hidden = true;
              };
          };
          settings = { # Check /home/yeshey/.mozilla/firefox/<user>/prefs.js to see these settings change
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
          '';
          userChrome = ''
          # a css 
          '';
          userContent = ''
          # Here too
          '';
        };
      in {
          # to switch profile go to about:profiles
          ${user} = common-conf;
          i2p = common-conf // {
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
        #test = {
        #  id = 1;
        #  name = "test";
        #  settings = {
        #      "general.autoScroll" = true;
        #  };
        #};
      };
    };

        # Shortcut to FIrfox i2p profile, but you need to be running the service: services.i2p.enable
        home.file.".local/share/applications/i2p.desktop".source = builtins.toFile "i2p.desktop" ''
  [Desktop Entry]
  Version=1.0
  Name=i2p
  Comment=i2p enabled firefox profile
  Exec=firefox -no-remote -P "i2p"
  Terminal=false
  StartupNotify=true
  Icon=firefox
  Type=Application
            '';

  };
}
