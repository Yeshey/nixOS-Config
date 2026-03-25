{
  inputs,
  self,
  ...
}:
{
  flake.modules.nixos.hyrulecastle =
    { config, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        yeshey
      ];

      # home-manager.users.yeshey = { # add something to this user on this machine
      #   ###
      # };
    };
}
