#
#  Home-manager configuration for desktop
#
#  flake.nix
#   └─ ./hosts
#       └─ ./desktop
#           └─ home.nix *
#

{ pkgs, lib, dataStoragePath, ... }:

let
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # so "~/Documents" becomes "Documents"
in
{

  home = {                                # Specific packages
    packages = with pkgs; [

    ];
  };

    # Make some folders not sync please
    home.file = {
      "${shortenedPath}/PersonalFiles/2023/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/2022/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Syncthing/PhoneCamera/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Syncthing/Allsync/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Music/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
    };
}