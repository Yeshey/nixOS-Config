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

    home.persistence."/persistent" = {
      # locations to spare religiously
      hideMounts = true;
      directories = [
        "PersonalFiles"
        "Downloads"
        "Music"
        "Pictures"
        "Documents"
        "Videos"
        ".setup"
        ".gnupg"
        ".local/share/direnv"
        ".config/syncthing"
        ".mozilla"
        #".config/vivaldi/"
        ".floorp"
        { directory = ".local/share/Steam"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".nixops"; mode = "0700"; }
        { directory = ".local/share/keyrings"; mode = "0700"; }

        ".local/share/baloo" # KDE plasma files index

        # syncthing
        ".stversions"
        ".stfolder"
      ];
      files = [
        # syncthing
        ".stignore"
        ".zsh_history"
        ".bash_history"
        ".python_history"
      ];
    };

  };
}
