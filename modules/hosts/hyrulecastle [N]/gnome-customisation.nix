let 
  username = "yeshey"; 
in
{
  flake.modules.nixos.hyrulecastle = 
    { lib, config, ... }: 
    {
      config = lib.mkIf config.systemConstants.isGnome {
        services.displayManager.gdm.autoSuspend = false;
      };
    };

  flake.modules.homeManager.${username} =
    { pkgs, lib, osConfig, ... }:
    {
      config = lib.mkIf (osConfig.systemConstants.isGnome or false) {
        home.packages = with pkgs; [
          gnomeExtensions.bing-wallpaper-changer
        ];

        dconf.settings = {
          "org/gnome/shell" = {
            disable-user-extensions = false;
            disabled-extensions = [
            ];
            enabled-extensions = [
              "BingWallpaper@ineffable-gmail.com"
            ];
          };

          "org/gnome/shell/extensions/bingwallpaper" = {
            hide = true;
            notify = true;
          };
        };
      };
    };
}