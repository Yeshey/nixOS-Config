{ inputs, lib, ... }:

let
  username = "guest";
in
{
  flake.modules.nixos."${username}" =
    { pkgs, ... }:
    {
      home-manager.users."${username}" = {
        imports = [
          inputs.self.modules.homeManager."${username}"
        ];
      };

      users.users."${username}" = {
        isNormalUser = true;
        description = "Guest User";
        initialPassword = "guest";
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "docker"
          "kvm"
          "libvirtd"
          "adbusers"
        ];
        shell = pkgs.zsh;
      };
      programs.zsh.enable = true;
    };

  flake.modules.homeManager."${username}" =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        system-desktop
        gnome-extensions
      ];

      home.username = "${username}";
      home.stateVersion = "25.11";
    };
}