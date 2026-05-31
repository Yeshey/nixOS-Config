{
  inputs,
  ...
}:
let
  username = "yeshey";
  myStoragePath = "/mnt/OneDrive/ISCTE";
in
{
  flake.modules.nixos.skyloft =
    { lib, ... }:
    {
      imports = [
        inputs.self.modules.nixos.${username}
      ];
      options.yeshey.dataStoragePath = lib.mkOption { type = lib.types.str; };
      config = {
        yeshey.dataStoragePath = myStoragePath;
        home-manager.users."${username}" = {
          "${username}".dataStoragePath = myStoragePath;
        };
      };
    };
}


