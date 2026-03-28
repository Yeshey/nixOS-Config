{
  inputs,
  ...
}:
let
  username = "guest";
in
{
  flake.modules.nixos.kakariko =
    {
      imports =   [
        inputs.self.modules.nixos.${username}
      ];

      home-manager.users."${username}" = { # add something to this user on this machine
        ###
      };
    };
}
