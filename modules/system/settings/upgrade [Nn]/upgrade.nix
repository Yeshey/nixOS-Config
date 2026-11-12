{
  flake.modules.nixos.upgrade =
    { config, ... }:
    {
      system.autoUpgrade = {
        enable = true;
        flake = "github:yeshey/nixos-config#${config.networking.hostName}";
        flags = [
          "--refresh"             # bypass tarball cache, see fresh lock
          "--no-write-lock-file"
          "-L"
        ];
        dates = "Sat *-*-* 07:00:00 UTC";
        allowReboot = false;
      };
    };

  flake.modules.homeManager.upgrade =
    { ... }:
    {
      services.home-manager.autoUpgrade = {
        enable = true;
        frequency = "Sat *-*-* 07:00:00 UTC";
        useFlake = true;
      };
    };
}