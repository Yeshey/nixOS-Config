{
  flake.modules.nixos.location =
    {
      services.automatic-timezoned.enable = true;

      services.avahi.enable = true;
    };
}