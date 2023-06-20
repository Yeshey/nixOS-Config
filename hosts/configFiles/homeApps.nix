#
#  Common Home-Manager Configuration
#

{ config, lib, pkgs, user, location, host, ... }:

{
  home = {
    packages = with pkgs; [
      github-desktop
      libnotify # so you can use notify-send
      obs-studio
      stremio
      barrier
      libsForQt5.neochat # plasma client for matrix
      # etcher #insecure?

      # Browsers
      vivaldi
      brave
      tor-browser-bundle-bin

      # tmp
      #teams
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

      #Follow the ask for help you did: (https://discourse.nixos.org/t/compiling-and-adding-program-not-in-nixpkgs-to-pc-compiling-error/25239/3)
      (callPackage ./playit-cli.nix {})
      vlc
      anydesk
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
      
      # Overlayed
      discord
      exodus
    ];
  };
}
