{
  inputs,
  ...
}:
let
  username = "yeshey";
  myStoragePath = "/home/${username}";
in
{
  flake.modules.nixos.onikao =
    { lib, ... }:
    {
      imports = [
        inputs.self.modules.nixos.${username}
      ];
      options.yeshey.dataStoragePath = lib.mkOption { type = lib.types.str; };
      config = {
        yeshey.dataStoragePath = myStoragePath;
        users.groups."${username}" = {};
        # users.users."${username}" = {
        #   isSystemUser = lib.mkForce true;  # or isSystemUser, pick one, not both, not neither
        #   group = username;
        # };
        home-manager.extraSpecialArgs = {
          dataStoragePath = myStoragePath;
        };
      };
    };
}


