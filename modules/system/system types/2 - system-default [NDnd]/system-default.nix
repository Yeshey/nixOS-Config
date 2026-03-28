{
  inputs,
  ...
}:
{
  # import all essential nix-tools which are used in all modules of a specific class

  flake.modules.nixos.system-default = {
    imports =
      with inputs.self.modules.nixos;
      [
        system-minimal
        home-manager
        safe-rm
        gc
        secrets
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
        pkgs-by-name
      ]);
  };

  flake.modules.darwin.system-default = {
    imports =
      with inputs.self.modules.darwin;
      [
        system-minimal
        determinate
        home-manager
        homebrew
        secrets
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
        pkgs-by-name
      ]);
  };

  # impermanence is not added by default to home-manager, because of missing Darwin implementation
  # for linux home-manager stand-alone configurations it has to be added manually

  flake.modules.homeManager.system-default = {
    imports =
      with inputs.self.modules.homeManager;
      [
        system-minimal
        safe-rm
        gc
        secrets
      ]
      ++ [ inputs.self.modules.generic.systemConstants ];
  };
}