{
  inputs,
  ...
}:
{
  flake.modules.nixos.gnome = {
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.gnome
    ];

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    programs.dconf.enable = true;
  };

  flake.modules.homeManager.gnome = {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        enable-hot-corners = true;
      };
      "org/nemo/preferences" = {
        confirm-move-to-trash = true;
      };
    };
  };
}
