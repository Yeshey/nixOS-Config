{ inputs, ... }:
{
  flake.modules.homeManager.desktop-apps =
    { pkgs, lib, ... }:
      lib.mkMerge [
        {
          home.packages = with pkgs; [
            inkscape
            vlc
            pdfarranger
            thunderbird
            wineWow64Packages.full
            restic-browser
            restic
            blanket
            zotero
            winboat
            vital # run with Vital
            helm
            kdePackages.okular
            unstable.joplin-desktop
            rnote
            github-desktop
            obs-studio
            bitwarden-desktop
            gparted
            baobab
            audacity
            unstable.floorp-bin
            brave
            tor-browser
            qutebrowser
            qpwgraph # ch.ange sound inputs and outputs

            # gaming
            unstable.osu-lazer-bin
            bottles
            prismlauncher # polymc # prismlauncher # for Minecraft
            heroic
            luanti
            the-powder-toy
          ];
          # settings for all systems
        }
        (lib.mkIf (pkgs.stdenv.isLinux) {
          home.packages = with pkgs; [
            libreoffice-qt6
            gimp3-with-plugins
          ];
          # NixOS settings
        })
        (lib.mkIf (pkgs.stdenv.isDarwin) {
          home.packages = with pkgs; [
            libreoffice-bin
            brewCasks.gimp
          ];
          # Nix-Darwin settings
        })
      ];
}