{ ... }:
{
  flake.modules.nixos.xrdp =
    { ... }:
    {
      environment.persistence."/persistent" = {
        files = [
          "/run/xrdp/rsakeys.ini" # server identity key
        ];
      };
    };
}