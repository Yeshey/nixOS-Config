# To see connected iphones
{
  flake.modules.nixos.iphone =
    { pkgs, ... }:
    {
      services.usbmuxd = {
        enable = true;
        package = pkgs.usbmuxd2;
      };

      services.gvfs.enable = true;

      environment.systemPackages = with pkgs; [
        libimobiledevice
        ifuse
      ];
    };
}