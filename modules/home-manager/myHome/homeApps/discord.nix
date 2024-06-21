{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.homeApps.discord;
in
{
  options.myHome.homeApps.discord = with lib; {
    enable = mkEnableOption "discord";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

    home.packages = with pkgs; [ 
      #vesktop
      discord 
    ];

    # My home files 
    home.file = {
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

    # TODO check and install themes? https://github.com/s-k-y-l-i/discord-themes

    #home.persistence = {
    #  "/persist/home/misterio".directories = [".config/vesktop"];
    #};

    /*
      xdg.configFile."vesktop/themes/base16.css".text = lib.mkIf ( config.myHome.colorScheme != null )
        # css
        ''
          @import url("https://slowstab.github.io/dracula/BetterDiscord/source.css");
          @import url("https://mulverinex.github.io/legacy-settings-icons/dist-native.css");
          .theme-dark, .theme-light, :root {
            --text-default: #${c.base05};
            --header-primary: #${c.base05};
            --header-secondary: #${c.base04};
            --channeltextarea-background: #${c.base02};
            --interactive-normal: #${c.base04};
            --interactive-active: #${c.base05};

            --dracula-primary: #${c.base00};
            --dracula-secondary: #${c.base01};
            --dracula-secondary-alpha: #${c.base01}ee;
            --dracula-tertiary: #${c.base03};
            --dracula-tertiary-alpha: #${c.base03}aa;
            --dracula-primary-light: #${c.base02};

            --dracula-accent: #${c.base09};
            --dracula-accent-alpha: #${c.base09}66;
            --dracula-accent-alpha-alt: #${c.base09}88;
            --dracula-accent-alpha-alt2: #${c.base09}aa;
            --dracula-accent-dark: #${c.base0E};
            --dracula-accent-light: #${c.base08};
          }

          html.theme-light #app-mount::after {
            content: none;
          }
        '';
    */
  };
}
