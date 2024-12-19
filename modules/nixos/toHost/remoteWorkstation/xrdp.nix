{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

# Connect with nix-shell -p freerdp --run "xfreerdp /v:143.47.53.175 /u:yeshey /dynamic-resolution /audio-mode:1 /clipboard /network:modem /compression"
# open port 3389
# set keyboard with `setxkbmap -layout br`, see what keyboard is set with `setxkbmap -print`
# see https://sourceforge.net/p/rdesktop/code/1704/tree/rdesktop/trunk/doc/keymap-names.txt#l78, idk, check chatGPT

let
  cfg = config.toHost.remoteWorkstation.xrdp;
in
{
  options.toHost.remoteWorkstation.xrdp = {
    enable = (lib.mkEnableOption "xrdp");
  };

  config = lib.mkIf cfg.enable {

    # Remote Desktop with XRDP
    # xfreerdp /v:143.47.53.175 /u:yeshey /dynamic-resolution /audio-mode:1 /clipboard
    # run `setxkbmap -layout pt` to get the pt layout
    #services.xserver.enable = true;
    #services.displayManager.sddm.enable = true;
    #services.desktopManager.plasma6.enable = true;
    services.xrdp.enable = true;
    services.xrdp.defaultWindowManager = "startplasma-x11";
    networking.firewall.allowedTCPPorts = [ 3389 ];
    services.xrdp.extraConfDirCommands = ''
      substituteInPlace $out/sesman.ini \
        --replace param=.xorgxrdp.%s.log param=/tmp/xorgxrdp.%s.log
    ''; # was taking 40GB in the server this file https://github.com/neutrinolabs/xrdp/issues/1845


    services = {
      xserver = {
        enable = true;    # X11 because setting up Wayland is more complicated than it is worth for me.
      };
      desktopManager.plasma6.enable = true;
      displayManager = {
        #autoLogin.enable = true;
        #autoLogin.user = config.mySystem.user;
        sddm.enable = true;
        defaultSession = "plasmax11";
      };
    };

  };
}
