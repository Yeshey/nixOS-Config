{
  flake.modules.nixos.location =
    { ... }:
    {
      services.geoclue2.enable = true;
      services.automatic-timezoned.enable = true;

      services.avahi.enable = true;
      systemd.services.avahi-daemon = {
        requires = [ "systemd-tmpfiles-resetup.service" ];
        after = [ "systemd-tmpfiles-resetup.service" ];
      };
    };
}