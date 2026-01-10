# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
# Generated with: nix-shell -p dconf2nix --command "dconf dump / | dconf2nix -e --verbose > dconf.nix"

# The above command didn't work, had to exclude some parts, this worked:
# nix shell nixpkgs#dconf nixpkgs#gawk nixpkgs-unstable#dconf2nix --command sh -c 'dconf dump / | gawk "/^\\[(com\\/github\\/flxzt\\/rnote|org\\/gnome\\/portal\\/filechooser\\/@joplinapp-desktop)\\]/ {skip=1; next} /^\\[/ {skip=0} !skip {print}" | dconf2nix -e --verbose > dconf.nix'

# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}@args:

let
  cfg = config.myHome.gnome;
in
with lib.hm.gvariant;
{
  config = lib.mkIf (config.myHome.enable && cfg.enable && config.home.username != "guest") {

    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        disabled-extensions = [
          # "rounded-window-corners@yilozt"
          # "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        ];
        enabled-extensions = [
          "burn-my-windows@schneegans.github.com"
          "copyous@boerdereinar.dev"
          "gnomelets@mcast.gnomext.com"
        ];
      };

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-timeout = 1500;
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-timeout = 900;
        sleep-inactive-battery-type = "nothing";
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

      "org/gnome/nautilus/preferences" = {
        click-policy = "single";
      };

    };
  };
}
