{
  inputs,
  ...
}:
{
  # expansion of default system with basic system settings & cli-tools

  flake.modules.nixos.system-cli-tier = {
    imports = with inputs.self.modules.nixos; [
      system-default-tier

      direnv
      shell
      starship
      ssh
      firmware
      cli-tools
      my-scripts
    ];
  };

  flake.modules.darwin.system-cli-tier = {
    imports = with inputs.self.modules.darwin; [
      system-default-tier

      direnv
      ssh
      cli-tools
    ];
  };

  flake.modules.homeManager.system-cli-tier = {
    imports = with inputs.self.modules.homeManager; [
      system-default-tier

      nh
      direnv
      shell
      starship
      cli-tools
      my-scripts
    ];
  };
}
