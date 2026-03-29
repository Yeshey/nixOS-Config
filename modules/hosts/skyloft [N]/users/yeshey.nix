{
  inputs,
  ...
}:
let
  username = "yeshey";
in
{
  flake.modules.nixos.skyloft =
    {
      imports = with inputs.self.modules.nixos; [
        inputs.self.modules.nixos.${username}
      ];

      home-manager.users."${username}" = {
        "${username}".dataStoragePath = "/home/${username}";
      };
    };
}
