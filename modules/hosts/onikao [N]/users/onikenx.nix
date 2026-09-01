{
  inputs,
  ...
}:
let
  username = "onikenx";
in
{
  flake.modules.nixos.onikao =
    {
      imports = [
        inputs.self.modules.nixos.${username}
      ];
      config = {
        home-manager.users."${username}" = { # add something to this user on this machine
          ###
        };
      };
    };
}