{
  inputs,
  ...
}:
let
  username = "yeshey";
  myStoragePath = "/home/${username}";
in
{
  flake.modules.nixos.kakariko =
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