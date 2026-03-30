{
  inputs,
  ...
}:
{
  # expansion of default system with basic system settings & cli-tools

  flake.modules.nixos.system-cli = {
    imports = with inputs.self.modules.nixos; [
      system-default

      direnv
      shell
      starship
      ssh
      firmware
      cli-tools
      my-scripts
    ];
  };

  flake.modules.darwin.system-cli = {
    imports = with inputs.self.modules.darwin; [
      system-default

      direnv
      ssh
      cli-tools
    ];
  };

  flake.modules.homeManager.system-cli = {
    imports = with inputs.self.modules.homeManager; [
      system-default

      nh
      direnv
      shell
      starship
      cli-tools
      my-scripts
    ];
  };
}
