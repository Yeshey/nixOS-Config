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
    enable = mkOption {
      type = types.bool;
      default = osConfig.mySystem.plasma.enable || osConfig.services.desktopManager.plasma6.enable;
      description = "personal KDE plasma configuration";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

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

    # to fix emojis in notifications and windows-key + V, etc. https://groups.google.com/g/linux.debian.bugs.dist/c/YLgE4_-sCbQ/m/xjoPbdv2AAAJ
    # made an issue in nixpkgs (https://github.com/NixOS/nixpkgs/issues/321826)
    #home.file.".config/fontconfig/conf.d/56-kubuntu-noto.conf".source = ./56-kubuntu-noto.conf;

  };
}
