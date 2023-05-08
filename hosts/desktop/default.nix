#
#  Specific system configuration settings for desktop
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ ./desktop
#   │        ├─ default.nix *
#   │        └─ hardware-configuration.nix
#   └─ ./modules
#       └─ ./desktop
#           └─ ./qemu
#               └─ default.nix
#

{ config, pkgs, user, location, dataStoragePath, lib, ... }:

let
  workingDir = "/opt/docker/fastapi-dls/cert";
in
{
imports = [
  (import ./hardware-configuration.nix)
  (import ./nixFiles/pci-passthrough.nix)
];

  # Following this github guide: https://github.com/tuh8888/libvirt_win10_vm

  # For GPU passthrough to the VM, but instead I'm going to try to use GPU virtualisation through the discovered jailbreak: https://github.com/DualCoder/vgpu_unlock
  # https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c
  pciPassthrough = {
    # you will also need to set hardware.nvidia.prime.offload.enable = true for this GPU passthrough to work
    enable = true;
    pciIDs = "";
    #pciIDs = "10de:1f11,10de:10f9,8086:1901,10de:1ada" ; # Nvidia VGA, Nvidia Audia,... "10de:1f11,10de:10f9,8086:1901,10de:1ada";
    libvirtUsers = [ "${user}" ];
  };

  #boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_5_10.override { 
  #  src = pkgs.fetchurl { 
  #    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.12.15.tar.xz";
  #    sha256 = "1k1ziz7v92k0w77sd7d07m51bdcac7vyil8cnn2h7i1a73bf2j7k";
  #  };
  #});
  
  #boot.kernelPackages = pkgs.linuxPackages_5_4; # needed for this

  #users.extraGroups.docker.members = [ "username-with-access-to-socket" ]; #(https://nixos.wiki/wiki/Docker)
  #virtualisation.docker.enable = true;
  #virtualisation.docker.enableOnBoot = true; # Big WTF
  # Help from https://github.com/NixOS/nixpkgs/issues/68349 and https://docs.docker.com/storage/storagedriver/btrfs-driver/
  #virtualisation.docker.storageDriver = "btrfs";

  /*
  systemd.timers."scream-receiver" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
        OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28"; # Every three days approximatley
        Unit = "delete-sync-conflicts.service";
      };
  };
  systemd.services."delete-sync-conflicts" = {
    script = ''
      ${pkgs.scream}/bin/scream -i virbr0
    '';
    # Ignore What's inside Trash etc...
    serviceConfig = {
      Type = "oneshot";
      User= "${user}";
    };
  };
  */

/*
sudo mkdir -p /opt/docker/fastapi-dls/cert

WORKING_DIR=/opt/docker/fastapi-dls/cert
mkdir -p $WORKING_DIR
cd $WORKING_DIR
# create instance private and public key for singing JWT's
openssl genrsa -out $WORKING_DIR/instance.private.pem 2048 
openssl rsa -in $WORKING_DIR/instance.private.pem -outform PEM -pubout -out $WORKING_DIR/instance.public.pem
# create ssl certificate for integrated webserver (uvicorn) - because clients rely on ssl
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout  $WORKING_DIR/webserver.key -out $WORKING_DIR/webserver.crt
 */

  virtualisation.oci-containers.containers = {
    fastapi-dls = {
      image = "collinwebdesigns/fastapi-dls:latest";
      volumes = [
        "${workingDir}:/app/cert:rw"
        "dls-db:/app/database"
      ];
      # Set environment variables
      environment = {
        TZ = "Europe/Lisbon";
        DLS_URL = "192.168.1.81"; # this should grab your hostname, not your IP!
        DLS_PORT = "443";
        LEASE_EXPIRE_DAYS="90";
        DATABASE = "sqlite:////app/database/db.sqlite";
        DEBUG = "true";
      };
      extraOptions = [
      ];
      # Publish the container's port to the host
      ports = [ "443:443" ];
      # Automatically start the container
      autoStart = true;
    };
  };

  hardware.nvidia = {
    vgpu = {
      enable = true; # Enable NVIDIA KVM vGPU + GRID driver
      unlock.enable = true; # Unlock vGPU functionality on consumer cards using DualCoder/vgpu_unlock project.
      #gridDriver = /mnt/DataDisk/Downloads/drivers/NVIDIA-Linux-x86_64-460.32.03-grid.run;
      #vgpuKvmDriver = /mnt/DataDisk/Downloads/drivers/NVIDIA-Linux-x86_64-460.73.01-grid-vgpu-kvm-v5.run;
    };
  };
  
  
  # Manage Temperature, prevent throttling
  # https://github.com/linux-surface/linux-surface/issues/221
  # laptop thermald with: https://github.com/intel/thermal_daemon/issues/42#issuecomment-294567400
  services.power-profiles-daemon.enable = true;
  services.thermald = {
    debug = false;
    enable = true;
    configFile = ./configFiles/thermal-conf.xml; #(https://github.com/linux-surface/linux-surface/blob/master/contrib/thermald/thermal-conf.xml)
  };
  systemd.services.thermald.serviceConfig.ExecStart = let # running with --adaptive ignores the config file. Issue raised: https://github.com/NixOS/nixpkgs/issues/201402
    cfg = config.services.thermald;
  in lib.mkForce ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            --config-file ${location}/hosts/desktop/configFiles/thermal-conf.xml \
        '';

  #services.thermald = {
  #  debug = false;
  #  enable = true;
  #};

  networking.hostName = "nixOS-Laptop"; # Define your hostname.
  # hardware.enableAllFirmware = true; #?

#     ___            __ 
#    / _ )___  ___  / /_
#   / _  / _ \/ _ \/ __/
#  /____/\___/\___/\__/      

  boot.loader = {

    timeout = 2;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      version = 2;
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

  # Docker 
  # Docker to automatically grab Epic Games Free games
  # Follow the service log with `journalctl -fu podman-epic_games.service`
  # You have to put the config.json5 file in /mnt/Epic_Games_Claimer/config.json5

  /*
  # My epic games accounts are not very well trusted anymore...
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true; # Big WTF
  # Help from https://github.com/NixOS/nixpkgs/issues/68349 and https://docs.docker.com/storage/storagedriver/btrfs-driver/
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.oci-containers.containers = {
    epic_games = {
      image = "charlocharlie/epicgames-freegames:latest";
      volumes = [ "/mnt/Epic_Games_Claimer:/usr/app/config:rw" ];
      ports = [ "3000:3000" ];
      # extraOptions = [ "-p 3000:3000"];
      # autoStart = true;
    };
  };
  */
  
  # tmp solution for audio not working
  # force VM to use pulseaudio, it seems to be necessary
  # What is mkForce and mkDefault and mkOverride: https://discourse.nixos.org/t/what-does-mkdefault-do-exactly/9028
  #services.pipewire.enable = lib.mkForce false; # same as mkoverride 50 - the option has a priority of 50
  #hardware.pulseaudio.enable = lib.mkForce true;
  #hardware.pulseaudio.support32Bit = true;    ## If compatibility with 32-bit applications is desired.
  #nixpkgs.config.pulseaudio = true;
  #hardware.pulseaudio.extraConfig = "load-module module-combine-sink";

  # KDE Plasma
  services.xserver = {
    enable = true; # Enable the X11 windowing system.
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "yeshey";
      sddm = {
        enable = true;
      };
      defaultSession = "plasma"; # "none+bspwm" or "plasma"
    };
    desktopManager.plasma5 = {
      enable = true;
      # supportDDC = true; # doesnt work with nvidia # to support changing brightness for external monitors (https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800)
    };
    # windowManager.bspwm.enable = true; # but doesn't work
  };

  environment.systemPackages = with pkgs; [

    # Epic_Games_Claimer
    # docker

    # tmp
    # virtualbox
    # texlive.combined.scheme-full # LaTeX
    looking-glass-client

    # Games
    steam
    grapejuice # roblox

    # FOR PLASMA DESKTOP
    scrot # for plasma config saver widget
    kdialog # for plasma config saver widget
    ark # Compress and Uncompress files
    sddm-kcm # for sddm configuration in settings
    kate # KDEs notepad    
  ];

  # Syncthing, there's no easy way to add ignore patters, so we're doing it like this for now:
  # But it looks like there also isn't an easy way to add them like we can in home manager with file.source...

}
