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
  imports = [ inputs.impermanence.homeManagerModules.impermanence ];

  options.myHome.impermanence = with lib; {
    enable = mkEnableOption "impermanence";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    home.persistence."/persistent/home/yeshey" = {
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
        #".config/vivaldi/"
        ".floorp"
        {
          directory = ".local/share/Steam";
          method = "symlink";
        }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".nixops"; mode = "0700"; }
        { directory = ".local/share/keyrings"; mode = "0700"; }
      ];
      files = [
        ".screenrc"
      ];
      allowOther = true;
    };

  };
}
