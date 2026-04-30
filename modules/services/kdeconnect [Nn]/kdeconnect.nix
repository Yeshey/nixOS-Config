{
  flake.modules.nixos.kdeconnect = {
  };

  flake.modules.homeManager.kdeconnect =
    { lib, osConfig, pkgs, ... }:
    {
      config = lib.mkMerge [
        (lib.mkIf osConfig.systemConstants.isGnome {
          home.packages = with pkgs; [
            gnomeExtensions.gsconnect
          ];

          dconf.settings = {
            "org/gnome/shell" = {
              enabled-extensions = [
                "gsconnect@andyholmes.github.io"
              ];
            };
          };
        })

        (lib.mkIf osConfig.systemConstants.isKdePlasma {
          services.kdeconnect = {
            enable = true;
            indicator = true;
          };
        })
      ];
    };
}