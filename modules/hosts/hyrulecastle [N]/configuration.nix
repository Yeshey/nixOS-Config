{ inputs, ... }:
{
  flake.modules.nixos.hyrulecastle = {
    imports = with inputs.self.modules.nixos; [
      system-desktop
      gnome
      yeshey
    ];

    networking.hostName = "hyrulecastle";

    boot.loader = {
      timeout = 2;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 15;
        memtest86.enable = true;
      };
    };

    nix.settings = {
      cores = 6;
      max-jobs = 4;
    };

    services.displayManager.gdm.autoSuspend = false;
    services.logind.settings.Login.HandleLidSwitch = "ignore";

    system.stateVersion = "22.05";
  };
}