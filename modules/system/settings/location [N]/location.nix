{
  flake.modules.nixos.location =
    { pkgs, ... }:
    {
      services.automatic-timezoned.enable = true;

      services.avahi.enable = true;
    };
}