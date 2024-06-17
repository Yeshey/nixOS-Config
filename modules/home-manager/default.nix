# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.

# TODO nur apps and firefox

{
  default =
    {
      inputs,
      config,
      lib,
      ...
    }:
    {
      # Nicely reload system units when changing configs
      systemd.user.startServices = lib.mkOverride 1010 "sd-switch";

      # TODO organize this:

      # My home files 
      home.file =
        /*
          let
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
                //
        */
        {

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
