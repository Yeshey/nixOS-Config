# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.

# TODO nur apps and firefox

{
  default = { inputs, config, lib, ... }: {

    #imports = [inputs.nix-colors.homeManagerModules.default];
    #colorScheme = inputs.nix-colors.colorSchemes.ocean;

    /*
  home.file.".config/user-dirs.dirs".source = builtins.toFile "user-dirs.dirs" ''
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="/mnt/DataDisk/Downloads/"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="/mnt/DataDisk/PersonalFiles/"
XDG_MUSIC_DIR="/mnt/DataDisk/PersonalFiles/Timeless/Music/"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
  '';
    # TODO change the above config to be like the one below
    xdg = {
      enable = lib.mkDefault true;
      userDirs = {
        enable = lib.mkDefault true;
        createDirectories = lib.mkDefault true;
        desktop = lib.mkDefault "${config.home.homeDirectory}/Pulpit";
        documents = lib.mkDefault "${config.home.homeDirectory}/Dokumenty";
        download = lib.mkDefault "${config.home.homeDirectory}/Pobrane";
        music = lib.mkDefault "${config.home.homeDirectory}/Muzyka";
        pictures = lib.mkDefault "${config.home.homeDirectory}/Obrazy";
        videos = lib.mkDefault "${config.home.homeDirectory}/Wideo";
        templates = lib.mkDefault "${config.home.homeDirectory}/Szablony";
        publicShare = lib.mkDefault "${config.home.homeDirectory}/Publiczny";
      };
    };
    */
    # Nicely reload system units when changing configs
    systemd.user.startServices = lib.mkDefault "sd-switch";

    # TODO, seems like backupFileExtension is enough? it 
    # xdg.configFile."*".force = true;

    # TODO organize this:
    
    # My home files 
    home.file = /* let
      autostartPrograms = [ pkgs.discord pkgs.premid pkgs.anydesk ];
    in builtins.listToAttrs (map
          # Startup applications with home manager
          # https://github.com/nix-community/home-manager/issues/3447
          (pkg:
            {
              name = ".config/autostart/" + pkg.pname + ".desktop";
              value =
                if pkg ? desktopItem then {
                  # Application has a desktopItem entry. 
                  # Assume that it was made with makeDesktopEntry, which exposes a
                  # text attribute with the contents of the .desktop file
                  text = pkg.desktopItem.text;
                } else {
                  # Application does *not* have a desktopItem entry. Try to find a
                  # matching .desktop name in /share/apaplications
                  source = (pkg + "/share/applications/" + pkg.pname + ".desktop");
                };
            })
          autostartPrograms)
          // */
          {

      # Syncthing shortcut, based on webapp manager created shortcut (https://github.com/linuxmint/webapp-manager)
      /*
      ".local/share/applications/vivaldi-syncthing.desktop".source = builtins.toFile "vivaldi-syncthing.desktop" ''
[Desktop Entry]
Version=1.0
Name=Syncthing
Comment=Web App
Exec=vivaldi --app="http://127.0.0.1:8384#" --class=WebApp-Syncthingvivaldi5519 --user-data-dir=/home/yeshey/.local/share/ice/profiles/Syncthingvivaldi5519
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=webapp-manager
Categories=GTK;WebApps;
MimeType=text/html;text/xml;application/xhtml_xml;
StartupWMClass=WebApp-Syncthingvivaldi5519
StartupNotify=true
X-WebApp-Browser=Vivaldi
X-WebApp-URL=http://127.0.0.1:8384#
X-WebApp-CustomParameters=
X-WebApp-Navbar=false
X-WebApp-PrivateWindow=false
X-WebApp-Isolated=true
          ''; */

      # MS WhiteBoard, based on webapp manager created shortcut (https://github.com/linuxmint/webapp-manager)
      ".local/share/applications/MSwhiteboard.desktop".source = builtins.toFile "MSwhiteboard.desktop" ''
[Desktop Entry]
Version=1.0
Name=MS WhiteBoard
Comment=Web App
Exec=vivaldi --app="https://whiteboard.office.com" --class=WebApp-MSwhiteboard2348 --user-data-dir=/home/yeshey/.local/share/ice/profiles/MSwhiteboard2348
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=webapp-manager
Categories=GTK;WebApps;
MimeType=text/html;text/xml;application/xhtml_xml;
StartupWMClass=WebApp-MSwhiteboard2348
StartupNotify=true
X-WebApp-Browser=Vivaldi
X-WebApp-URL=https://whiteboard.office.com
X-WebApp-CustomParameters=
X-WebApp-Navbar=false
X-WebApp-PrivateWindow=false
X-WebApp-Isolated=true
          '';

      # Make a symlinks for Syncthing Ignore file:
      ".stignore".source = builtins.toFile ".stignore" ''
!/.zsh_history
!/.bash_history
!/.python_history
// Ignore everything else:
*
          '';

      # So it doesn't sync for example the mouse sensitivity between devices
      ".local/share/osu/.stignore".source = builtins.toFile ".stignore" ''
// Don't ignore these files...
!/files
!/screenshots
!/collection.db
!/client.realm

// Ignore everything else in osu folder
*
        '';

      # So it doesn't sync for example the mouse sensitivity between devices
      ".local/share/Mindustry/.stignore".source = builtins.toFile ".stignore" ''
// Don't ignore these files...

// Ignore everything else in Mindustry folder
// *
        '';

      # For discord to start correctly (from nixOS wiki discord page)
      ".config/discord/settings.json".source = builtins.toFile "file.file" ''
{
  "IS_MAXIMIZED": false,
  "IS_MINIMIZED": true,
  "SKIP_HOST_UPDATE": true,
  "WINDOW_BOUNDS": {
    "x": 173,
    "y": 68,
    "width": 1630,
    "height": 799
  }
}
          '';
    };
  };
  myHome = import ./myHome;
}
