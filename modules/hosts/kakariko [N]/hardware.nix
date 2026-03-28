{ inputs, ... }:
{
  flake.modules.nixos.kakariko =
    { config, lib, pkgs, modulesPath, ... }:
    let
      hdaJackRetaskFwContent = ''
        [codec]
        0x10ec0274 0x10ec11e8 0

        [pincfg]
        0x12 0xb7a60130
        0x13 0x40000000
        0x14 0x411111f0
        0x15 0x411111f0
        0x16 0x411111f0
        0x17 0x411111f0
        0x18 0x411111f0
        0x19 0x90a60160
        0x1a 0x411111f0
        0x1b 0x90170110
        0x1d 0x4066192d
        0x1e 0x411111f0
        0x1f 0x411111f0
        0x21 0x03211020
      '';
      hdaJackRetaskFwPkg = pkgs.runCommand "hda-jack-retask-custom-fw" { } ''
        mkdir -p $out/lib/firmware
        echo "${hdaJackRetaskFwContent}" > $out/lib/firmware/hda-jack-retask.fw
      '';
    in
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
      ];

      services.thermald = {
        enable = true;
        configFile = ./thermal-conf.xml;
      };

      # if thermald isn't working properly activate this (not sure if needed)
      systemd.services.restart-thermald = {
        description = "Restart thermald after 10 seconds";
        after = [ "network.target" "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          echo "restarting thermald to make sure it works..."
          ${pkgs.systemd}/bin/systemctl restart thermald
        '';
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 40";
        };
      };

      boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      boot.initrd.kernelModules = [ "dm-snapshot" ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];
      
      hardware.firmware = [ hdaJackRetaskFwPkg ];
      # environment.variables.INTEL_DEBUG = "reemit"; # for wot?
      services.bcachefs.autoScrub.enable = true; # enable after you have kernel 6.14 or later
      hardware.microsoft-surface.kernelVersion = "stable"; # newer kernel
      boot.initrd.preLVMCommands = lib.mkOrder 400 "sleep 7"; # I have to wait a bit to let my hardware pick up on my microSD

      swapDevices = [{ 
        device = "/dev/disk/by-label/nvmeswap";
        priority = 1; # Higher numbers higher priority.
      }];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      systemd.services.fix-surface-clock = {
        description = "Fix broken Surface RTC using ntpdate";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        script = ''
          ${pkgs.ntp}/bin/ntpdate -u pool.ntp.org || \
          ${pkgs.ntp}/bin/ntpdate -u time.cloudflare.com || \
          ${pkgs.ntp}/bin/ntpdate -u time.google.com
        '';
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    };
}