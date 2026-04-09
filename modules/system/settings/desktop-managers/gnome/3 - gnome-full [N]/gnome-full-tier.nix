{
  inputs,
  ...
}:
{
  flake.modules.nixos.gnome-full-tier = {
    imports = with inputs.self.modules.nixos; [
      gnome-base-tier
    ];
  };

  flake.modules.homeManager.gnome-full-tier = 
    { pkgs, ... }: 
    {
      imports = with inputs.self.modules.homeManager; [
        gnome-base-tier
      ];

      home.packages = with pkgs; [
        gnomeExtensions.appindicator # system tray
        gnomeExtensions.system-monitor # official gnome extension
        gnomeExtensions.user-themes # # official gnome extension
        gnomeExtensions.caffeine
        # waiting for this issue to get fixed: https://github.com/boerdereinar/copyous/issues/67
        (unstable.gnomeExtensions.copyous.overrideAttrs (old: {
          buildInputs = [
            pkgs.libgda5
          ];
          preInstall = ''
            sed -i "1i import GIRepository from 'gi://GIRepository';\nGIRepository.Repository.dup_default().prepend_search_path('${pkgs.libgda5}/lib/girepository-1.0');\nGIRepository.Repository.dup_default().prepend_search_path('${pkgs.gsound}/lib/girepository-1.0');\n" lib/preferences/dependencies/dependencies.js
            sed -i "1i import GIRepository from 'gi://GIRepository';\nGIRepository.Repository.dup_default().prepend_search_path('${pkgs.libgda5}/lib/girepository-1.0');\n" lib/misc/db.js
          '';
        }))
      ];

      dconf.settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          disabled-extensions = [
          ];
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com" # system tray
            "system-monitor@gnome-shell-extensions.gcampax.github.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "copyous@boerdereinar.dev"
            "caffeine@patapon.info"
          ];
        };

        "org/gnome/shell/extensions/appindicator" = {
          tray-pos = "left";
        };
        
        "org/gnome/shell/extensions/system-monitor" = {
          show-download = false;
          show-upload = false;
        };
      };
    };
}