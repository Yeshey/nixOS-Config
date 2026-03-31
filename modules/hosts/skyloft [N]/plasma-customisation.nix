{
  inputs,
  ...
}:
{
  flake.modules.homeManager.skyloft =
    { lib, osConfig, ... }:
    {
      imports = [ inputs.plasma-manager.homeModules.plasma-manager ];
      config = lib.mkIf (osConfig.systemConstants.isKdePlasma or false) {
        programs.plasma.configFile."powerdevilrc"."AC/RunScript" = {
          "IdleTimeoutCommand" = lib.mkForce "qdbus org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout";
          "idleTime" = lib.mkForce 600000;
        };
      };
    };
}