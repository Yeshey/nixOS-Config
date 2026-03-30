# Connect with:
# nix-shell -p freerdp --run "xfreerdp /v:<host> /u:yeshey /dynamic-resolution /kbd:0x0816 /audio-mode:1 /clipboard /network:modem /compression"
# Or for high-DPI (e.g. Surface Pro 7):
# nix-shell -p freerdp --run "xfreerdp /v:<host> /u:yeshey /w:1920 /h:1080 /smart-sizing /kbd:0x0816 /audio-mode:1 /clipboard /network:modem /compression"
# /kbd:0x0816 = Portuguese keyboard, /kbd:0x0416 = Brazilian keyboard
# Set keyboard layout at runtime with: setxkbmap -layout pt
# Open port 3389

{ inputs, ... }:
{
  flake.modules.nixos.xrdp =
    { lib, ... }:
    {
      services.xrdp = {
        enable = true;
        defaultWindowManager = "startplasma-x11";
        extraConfDirCommands = ''
          substituteInPlace $out/sesman.ini \
            --replace param=.xorgxrdp.%s.log param=/tmp/xorgxrdp.%s.log
        ''; # prevent log file from filling disk: https://github.com/neutrinolabs/xrdp/issues/1845
      };

      # X11 because Wayland over xrdp is more trouble than it's worth
      services.xserver = {
        enable = true;
        xkb = {
          layout = "pt";
          variant = "";
        };
      };

      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = lib.mkOverride 1010 true;

      networking.firewall.allowedTCPPorts = [ 3389 ];
    };
}