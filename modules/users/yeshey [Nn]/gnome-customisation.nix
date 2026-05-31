# dconf dump / > dconf-settings.ini
let 
  username = "yeshey"; 
in
{
  flake.modules.homeManager.${username} =
    { pkgs, lib, osConfig, ... }:
    {
      config = lib.mkIf (osConfig.systemConstants.isGnome or false) {
        home.packages = with pkgs; [
          networkmanagerapplet # Has for example "Automatically connect to VPN when using this connection"
          
          gnomeExtensions.power-off-options
          gnomeExtensions.burn-my-windows
          unstable.gnomeExtensions.gnomelets
          gnomeExtensions.night-theme-switcher
        ];

        dconf.settings = {
          "org/gnome/shell" = {
            disable-user-extensions = false;
            disabled-extensions = [
            ];
            enabled-extensions = [
              "burn-my-windows@schneegans.github.com"
              "gnomelets@mcast.gnomext.com"
              "power-off-options@axelitama.github.io"
              "nightthemeswitcher@romainvigier.fr"
            ];
          };

          "org/gnome/shell/extensions/power-off-options" = {
            show-reboot-to-bios=true;
          };

          "org/gnome/shell/extensions/burn-my-windows" = {
            close-preview-effect = "";
            fire-close-effect = false;
            glide-close-effect = false;
            glitch-close-effect = true;
            glitch-open-effect = true;
            hexagon-animation-time = 600;
            hexagon-close-effect = false;
            hexagon-open-effect = true;
            incinerate-animation-time = 1000;
            incinerate-close-effect = false;
            open-preview-effect = "";
            tv-close-effect = true;
            tv-open-effect = false;
            wisps-open-effect = false;
          };

          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-timeout = 1500;
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-battery-timeout = 900;
            sleep-inactive-battery-type = "nothing";
          };

          "org/gnome/nautilus/preferences" = {
            click-policy = "single";
          };
        };
      };
    };
}