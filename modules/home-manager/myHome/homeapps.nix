{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.homeapps;
in
{
  options.myHome.homeapps = with lib; {
    enable = mkEnableOption "homeapps";
  };

  config = lib.mkIf cfg.enable {
  home = {
    packages = with pkgs; [
      github-desktop
      libnotify # so you can use notify-send
      obs-studio
      stremio
      barrier
      bitwarden
      #libsForQt5.neochat # plasma client for matrix
      # etcher #insecure?

      # Browsers
      vivaldi
      brave
      tor-browser-bundle-bin
      qutebrowser
      # librewolf

      # tmp
      skypeforlinux
      #staruml # UML diagrams
      #jetbrains.clion # C++
      #jetbrains.idea-community # java

      # Games
      osu-lazer
      lutris
      # tetrio-desktop # runs horribly, better on the web
      prismlauncher # polymc # prismlauncher # for Minecraft
      heroic
      minetest
      the-powder-toy
      mindustry
      helvum

      #Follow the ask for help you did: (https://discourse.nixos.org/t/compiling-and-adding-program-not-in-nixpkgs-to-pc-compiling-error/25239/3)
      # (callPackage ./playit-cli.nix {}) # TODO the files have been moved to /pkgs, fix
      # (callPackage ./ipfs-sync.nix {}) # TODO the files have been moved to /pkgs, fix
      vlc
      # anydesk
      pdfarranger
      # helvum # To control pipewire Not Working?
      virt-manager # virtual machines
      virt-viewer # needed to choose share folders with windows VM (guide and video: https://www.guyrutenberg.com/2018/10/25/sharing-a-folder-a-windows-guest-under-virt-manager/ and https://www.youtube.com/watch?v=Ow3gVbkWj-c)
      spice-gtk # for virtual machines (to connect usbs and everything else)
      linux-wifi-hotspot # hotspot
      scrcpy # screen cast android phone
      ocrmypdf
      # texlive.combined.scheme-full # LaTeX

      # for amov, flutter need this
      #flutter # Dart, for amov # Make it detect android studio: https://github.com/flutter/flutter/issues/18970#issuecomment-762399686
      # also do this: https://stackoverflow.com/questions/60475481/flutter-doctor-error-android-sdkmanager-tool-not-found-windows
      #clang
      #cmake
      #ninja
      #pkg-config
      
      #discord
      exodus
    ];
  };

  /* 
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
          */
  };
}
