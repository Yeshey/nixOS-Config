{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.general;
in
{
  options.myHome.homeApps.general = with lib; {
    enable = mkEnableOption "general";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

    # home.persistence."/persist/home/yeshey" = {
    #   directories = [
    #     ".config/vivaldi/"
    #   ];
    #   allowOther = true;
    # };

    home = {
      packages = with pkgs; let
        cus_vivaldi = pkgs.vivaldi.overrideAttrs (oldAttrs: {
          dontWrapQtApps = false;
          dontPatchELF = true;
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.kdePackages.wrapQtAppsHook ];
        });

        pkgs_old_wihotspot = import (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/67b4bf1df4ae54d6866d78ccbd1ac7e8a8db8b73.tar.gz";
            sha256 = "sha256:07gzgcgaclgand7j99w45r07gc464b5jbpaa3wmv6nzwzdb3v3q4";
        }){ inherit (pkgs) system; };
        old_wihotspot = pkgs_old_wihotspot.linux-wifi-hotspot;

      in [
        # nexusmods-app-unfree # for game mods?
        # input-leap # :(
        wineWow64Packages.full
        restic-browser
        restic
        blanket
        zotero

        #jetbrains-toolbox # for code with me you need the toolbox
        #jetbrains.gateway

        vital # run with Vital
        helm
        kdePackages.okular

        unstable.joplin-desktop # note taking
        # unstable.zed-editor
        rnote

        github-desktop
        obs-studio
        stremio
        #barrier
        bitwarden
        gparted
        baobab
        anki
        xclip # for vim clipboard support :)
        # etcher #insecure?
        audacity

        # Browsers
        # cus_vivaldi
        #vivaldi
        #floorp # disabled bc https://iscteiul365.sharepoint.com/ doesn't work in nixOS floorp version # in about:config set browser.tabs.tabMinWidth to 50 and browser.ctrlTab.sortByRecentlyUsed to true
        brave
        tor-browser-bundle-bin
        qutebrowser
        # firefox
        # librewolf

        qpwgraph # change sound inputs and outputs

        vlc
        # anydesk
        pdfarranger
        # old_wihotspot
        linux-wifi-hotspot # hotspot
        # texlive.combined.scheme-full # LaTeX

        # for amov, flutter need this
        #flutter # Dart, for amov # Make it detect android studio: https://github.com/flutter/flutter/issues/18970#issuecomment-762399686
        # also do this: https://stackoverflow.com/questions/60475481/flutter-doctor-error-android-sdkmanager-tool-not-found-windows
        #clang
        #cmake
        #ninja
        #pkg-config

        #discord
        #exodus
      ];
    };
  };
}
