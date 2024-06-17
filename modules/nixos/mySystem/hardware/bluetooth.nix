{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware.bluetooth;
in
{
  options.mySystem.hardware.bluetooth = {
    enable = lib.mkEnableOption "bluetooth";
  };

  config = lib.mkIf (config.mySystem.enable && config.mySystem.hardware.enable && cfg.enable) {
    # Bluetooth
    hardware.bluetooth = {
      # TODO Check if it's still needed
      powerOnBoot = true;
      enable = true;
      # package = pkgs.bluezFull;
    };
    # https://github.com/NixOS/nixpkgs/issues/63703 (issue that helped me override it)
    # https://discourse.nixos.org/t/how-to-override-nixpkg-services-execstart/17699 (general systemd service override)
    # https://forum.manjaro.org/t/how-to-monitor-battery-level-of-bluetooth-device/117769 (where I found the solution to report connected bluetooth devices battery)
    systemd.services.bluetooth.serviceConfig.ExecStart = [
      # I guess you don't need this: lib.mkForce
      ""
      "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf --experimental"
    ];
  };
}
