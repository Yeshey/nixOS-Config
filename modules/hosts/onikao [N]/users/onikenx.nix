{
  inputs,
  ...
}:
let
  username = "onikenx";
  myStoragePath = "/home/${username}";
in
{
  flake.modules.nixos.onikao =
    { lib, ... }:
    {
      imports = [
        inputs.self.modules.nixos.${username}
      ];
      options.onikenx.dataStoragePath = lib.mkOption { type = lib.types.str; };
      config = {
        onikenx.dataStoragePath = myStoragePath;
        users.groups."${username}" = {};
        # users.users."${username}" = {
        #   isNormalUser = lib.mkForce true;
        #   group = username;
        # };
        home-manager.extraSpecialArgs = {
          dataStoragePath = myStoragePath;
        };
      };
    };
}