{
  flake.modules.homeManager.desktop-apps =
    { pkgs, lib, ... }:
      lib.mkMerge [
        {
          home.packages = with pkgs; [
            inkscape
            blender 
            vlc
            pdfarranger
            thunderbird
            wineWow64Packages.full
            restic-browser
            restic
            zotero
            pkgs.unstable.winboat
            vital # run with Vital
            helm
            kdePackages.okular
            unstable.joplin-desktop
            rnote
            github-desktop
            obs-studio
            gparted
            baobab
            audacity
            unstable.floorp-bin
            brave
            tor-browser
            qutebrowser
            qpwgraph # change sound inputs and outputs

            # gaming
            unstable.osu-lazer-bin
            prismlauncher # polymc # prismlauncher # for Minecraft
            heroic
            the-powder-toy
            gnome-connections

            # Global Protect VPN to connect to ISCTE
            (pkgs.makeDesktopItem {
              name = "gpclient-iscte";
              desktopName = "GlobalProtect ISCTE-IUL";
              genericName = "GlobalProtect VPN Client";
              comment = "Connect to ISCTE-IUL VPN";
              exec = "sudo ${pkgs.gpclient}/bin/gpclient --fix-openssl connect vpn.iscte-iul.pt --browser firefox";
              icon = "network-vpn";
              categories = [ "Network" "Dialup" ];
              keywords = [
                "GlobalProtect"
                "Openconnect"
                "SAML"
                "connection"
                "VPN"
              ];
              mimeTypes = ["x-scheme-handler/globalprotectcallback"];
              terminal = true;
            })
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

  flake.modules.nixos.desktop-apps = 
    { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        vscode
      ];
    };
}