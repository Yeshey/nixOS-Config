{ inputs, lib, ... }:

let
  username = "yeshey";
in
{
  flake.modules.homeManager."${username}" =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        system-desktop
        gnome
      ];

      home.username = "${username}";
      home.stateVersion = lib.mkDefault "22.05";
    };
}