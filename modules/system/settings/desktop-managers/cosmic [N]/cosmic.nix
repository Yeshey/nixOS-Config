{
  inputs,
  ...
}:
{
  flake.modules.nixos.cosmic = {
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.cosmic
    ];

    services.displayManager.cosmic-greeter.enable = true; # Enable the COSMIC login manager
    services.desktopManager.cosmic.enable = true; # Enable the COSMIC desktop environment
    environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1; # for global clipboard - https://wiki.nixos.org/wiki/COSMIC
    programs.firefox.preferences = {
      "widget.gtk.libadwaita-colors.enabled" = false; # disable libadwaita theming for Firefox
    };
  };

  flake.modules.homeManager.cosmic = { };
}