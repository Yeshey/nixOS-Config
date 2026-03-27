let
  username = "yeshey";
in
{
  flake.modules.homeManager.${username} = 
    { pkgs, lib, config, osConfig, ... }: 
    let
      isGnome = osConfig.services.desktopManager.gnome.enable or false;
    in
    {
      options.${username}.enableGnomeCustomizations = lib.mkOption {
        type = lib.types.bool;
        default = isGnome || false; # osConfig detects gnome in NixOS, and you can override in HM standalone
        description = "Enable ${username}'s gnome customizations. Auto-detected on NixOS, set manually for standalone HM.";
      };

      config = lib.mkIf config.${username}.enableGnomeCustomizations {
        home.packages = with pkgs; [
          networkmanagerapplet # Has for example "Automatically connect to VPN when using this connection"
          
          gnomeExtensions.power-off-options
          gnomeExtensions.burn-my-windows
          unstable.gnomeExtensions.gnomelets
          gnomeExtensions.night-theme-switcher
          banana-cursor # for the cursor
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

          "org/gnome/desktop/interface" = {
            cursor-theme = "Banana";
          };

          "org/gnome/nautilus/preferences" = {
            click-policy = "single";
          };
        };
      };
    };
}