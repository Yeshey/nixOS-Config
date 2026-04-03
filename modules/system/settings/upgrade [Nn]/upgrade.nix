{
  flake.modules.nixos.upgrade =
    { config, ... }:
    {
      system.autoUpgrade = {
        enable      = true;
        flake       = "github:yeshey/nixos-config#${config.networking.hostName}";
        flags       = [
          "--update-input" "nixpkgs"
          "--no-write-lock-file"
          "-L"                        # print build logs
        ];
        dates       = "weekly";
        allowReboot = false;          # set to true on servers that can reboot unattended
      };
    };
}