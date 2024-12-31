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
      in [
        wineWow64Packages.full

        vital # run with Vital
        helm
        okular

        unstable.joplin-desktop # note taking
        unstable.zed-editor
        rnote

        github-desktop
        obs-studio
        stremio
        #barrier
        #input-leap
        bitwarden
        gparted
        baobab
        anki
        xclip # for vim clipboard support :)
        # etcher #insecure?
        audacity

        # Browsers
        cus_vivaldi
        #vivaldi
        floorp # in about:config set browser.tabs.tabMinWidth to 50 and browser.ctrlTab.sortByRecentlyUsed to true
        brave
        tor-browser-bundle-bin
        qutebrowser
        # firefox
        # librewolf

        qpwgraph # change sound inputs and outputs

        vlc
        # anydesk
        pdfarranger
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
