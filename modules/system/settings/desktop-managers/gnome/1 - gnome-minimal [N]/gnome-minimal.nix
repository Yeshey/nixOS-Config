{
  inputs,
  ...
}:
{
  flake.lib.mkIfGnome =
    config: settings:
    let
      isGnome =
        if config ? osConfig
        then config.osConfig.services.desktopManager.gnome.enable or false  # HM module context
        else config.services.desktopManager.gnome.enable or false;           # NixOS module context
    in
    if isGnome then settings else { };

  flake.modules.nixos.gnome-minimal = 
    { lib, ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.gnome-minimal
      ];
      services.displayManager.gdm = {
        enable = true;
      };
      services.desktopManager.gnome.enable = true;

      programs.ssh.startAgent = lib.mkForce false;
    };

  flake.modules.homeManager.gnome-minimal = { };
}