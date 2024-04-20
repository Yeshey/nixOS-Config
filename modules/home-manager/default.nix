# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.

# TODO nur apps and firefox

{
  default = { inputs, config, lib, ... }: {
    # Nicely reload system units when changing configs
    systemd.user.startServices = lib.mkDefault "sd-switch";

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
