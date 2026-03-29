{
  flake.modules.nixos.location =
    { pkgs, ... }:
    {
      services.geoclue2.enable = true;
      services.automatic-timezoned.enable = true;

      services.avahi.enable = true;
    };
}