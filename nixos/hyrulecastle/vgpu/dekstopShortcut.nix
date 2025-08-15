{ config, pkgs, lib, ... }:

let
  runWindowsVM = pkgs.makeDesktopItem {
    name        = "runWindowsVM";
    desktopName = "Windows 11";
    exec        = "${pkgs.writeShellScriptBin "runWindowsVMscript" ''
      looking-glass-client win:fullScreen spice:alwaysShowCursor || {
        echo "Failed to start Looking Glass."
        echo "Make sure your Windows 11 VM is running in virt-manager."
      }
    ''}/bin/runWindowsVMscript %f";
    icon = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/yeyushengfan258/Win11-icon-theme/main/src/apps/scalable/distributor-logo-windows.svg";
      sha256 = "sha256-vGx0jSojRdNGo0gzH/xR5vpH3yqitS3FQrDfKDqWn9s=";
    };
    categories  = [ "Game" "Utility" ];
    type        = "Application";
    terminal = true;
  };
in
{
  environment.systemPackages = [ runWindowsVM ];
}