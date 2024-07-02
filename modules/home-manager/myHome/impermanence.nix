{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.impermanence;
in
{
  imports = [ inputs.impermanence.nixosModules.home-manager.impermanence ];

  options.myHome.impermanence = with lib; {
    enable = mkEnableOption "impermanence";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    home.persistence."/persist/home/yeshey" = {
      # locations to spare religiously
      directories = [
        "PersonalFiles"
        "Downloads"
        "Music"
        "Pictures"
        "Documents"
        "Videos"
        ".gnupg"
        ".ssh"
        ".nixops"
        ".local/share/keyrings"
        ".local/share/direnv"
        
        ".config/syncthing"
        ".mozilla"
        ".config/vivaldi/"
        {
          directory = ".local/share/Steam";
          method = "symlink";
        }
      ];
      files = [
        ".screenrc"
      ];
      allowOther = true;
    };

  };
}
