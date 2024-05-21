{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
  };

  mySystem = {
    gnome.enable = true; # TODO, we can do better
    plasma.enable = false;
    gaming.enable = true;
    ssh.enable = true;
    vmHost = true;
    dockerHost = true;
    host = "twilightrealm"; # TODO make this mandatory?
    home-manager = {
      enable = true;
      home = ./home.nix;
      # useGlobalPkgs = lib.mkForce false;
    };
    bluetooth.enable = true;
    printers.enable = true;
    sound.enable = true;
    flatpaks.enable = false;

    nvidia = {
      enable = true;
      intelBusId = "PCI:0:1:0";
      nvidiaBusId = "PCI:8:0:0";
    };
    agenix = {
      enable = true;
      sshKeys.enable = true;
    };
  };

  boot.kernelParams = [ "nouveau.modeset=0" ];

  boot.loader = {

    timeout = 2;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      device = "nodev";
      useOSProber = true;
      # default = "saved"; # doesn't work with btrfs :(
      extraEntries = ''
        menuentry "Reboot" {
            reboot
        }

        menuentry "Shut Down" {
            halt
        }

        # Option info from /boot/grub/grub.cfg, technotes "Grub" section for more details
        menuentry "NixOS - Console" --class nixos --unrestricted {
        search --set=drive1 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
        search --set=drive2 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
          linux ($drive2)/@/nix/store/ll70jpkp1wgh6qdp3spxl684m0rj9ws4-linux-5.15.68/bzImage init=/nix/store/c2mg9sck85ydls81xrn8phh3i1rn8bph-nixos-system-nixos-22.11pre410602.ae1dc133ea5/init loglevel=4 3
          initrd ($drive2)/@/nix/store/s38fgk7axcjryrp5abkvzqmyhc3m4pd1-initrd-linux-5.15.68/initrd
        }

      '';
    };
  };

  # swap in ext4:
  swapDevices = [
    {
      device = "/swapfile";
      priority = 0; # Higher numbers indicate higher priority.
      size = 6 * 1024;
      options = [ "nofail" ];
    }
  ];

  services.spice-vdagentd.enable = true;

  environment.systemPackages = with pkgs; [
    # Games
    steam
  ];

  system.stateVersion = "22.05";
}
