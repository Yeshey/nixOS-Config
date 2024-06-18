{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.myHome.plasma;
in
{
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  options.myHome.plasma = with lib; {
    enable = mkEnableOption "plasma";
  };

  config = lib.mkIf (config.myHome.enable && (cfg.enable || osConfig.mySystem.plasma.enable == true)) {

    # hope it doesn't conflict with stylix 🤞
    programs.plasma = {
      enable = true;
      workspace = {
        clickItemTo = "open";
        #lookAndFeel = "org.kde.breezedark.desktop";
        #cursorTheme = "Bibata-Modern-Ice";
        #iconTheme = "Papir";
        #wallpaper = ... # conflicts with stylix
      };
    };
  };
}
