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
        # etcher #insecure?

        # Browsers
        #vivaldi
        brave
        tor-browser-bundle-bin
        qutebrowser
        # firefox
        # librewolf

        helvum

        #Follow the ask for help you did: (https://discourse.nixos.org/t/compiling-and-adding-program-not-in-nixpkgs-to-pc-compiling-error/25239/3)
        # (callPackage ./playit-cli.nix {}) # TODO the files have been moved to /pkgs, fix
        # (callPackage ./ipfs-sync.nix {}) # TODO the files have been moved to /pkgs, fix
        vlc
        # anydesk
        pdfarranger
        # helvum # To control pipewire Not Working?
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
        exodus
      ];
    };
  };
}
