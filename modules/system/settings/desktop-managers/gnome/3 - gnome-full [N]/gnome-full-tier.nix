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
        gnomeExtensions.copyous
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