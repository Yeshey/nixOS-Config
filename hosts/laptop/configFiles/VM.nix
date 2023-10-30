{ config, pkgs, user, location, dataStoragePath, lib, ... }:

{
  imports = [
    (import ./pci-passthrough.nix)
    (import (builtins.fetchurl{
          url = "https://github.com/NixOS/nixpkgs/raw/63c34abfb33b8c579631df6b5ca00c0430a395df/nixos/modules/programs/looking-glass.nix";
          sha256 = "sha256:1lfrqix8kxfawnlrirq059w1hk3kcfq4p8g6kal3kbsczw90rhki";
        } ))  #(import ./nixFiles/looking-glass.nix)
  ];

  # Following this github guide: https://github.com/tuh8888/libvirt_win10_vm

  # For GPU passthrough to the VM, but instead I'm going to try to use GPU virtualisation through the discovered jailbreak: https://github.com/DualCoder/vgpu_unlock
  # https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c
  pciPassthrough = {
    # you will also need to set hardware.nvidia.prime.offload.enable = true for this GPU passthrough to work  (or the sync method?)
    enable = true;
    pciIDs = "";
    #pciIDs = "10de:1f11,10de:10f9,8086:1901,10de:1ada" ; # Nvidia VGA, Nvidia Audia,... "10de:1f11,10de:10f9,8086:1901,10de:1ada";
    libvirtUsers = [ "${user}" ];
  };

  programs.looking-glass = let
    # Looking glass B6 version in nix: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/virtualization/looking-glass-client/default.nix
    myPkgs = import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/9fa5c1f0a85f83dfa928528a33a28f063ae3858d.tar.gz";
        sha256 = "sha256:1f98dpg7jw8i913m4wag6amp49535dg0vr4qms9r63y4h3llw7s7";
    }) {};

    LookingGlassB6 = myPkgs.looking-glass-client;
  in {
    enable = true;
    package = LookingGlassB6;
  };

  # For the VM
  /*
  boot.kernelPackages = pkgs.linuxPackages_5_15; # needed for this linuxPackages_5_19
  hardware.nvidia = {
    vgpu = {
      enable = true; # Install NVIDIA KVM vGPU + GRID driver
      unlock.enable = true; # Unlock vGPU functionality on consumer cards using DualCoder/vgpu_unlock project.
      fastapi-dls = {
        enable = true;
        local_ipv4 = "localhost"; #"192.168.1.109";
        timezone = "Europe/Lisbon";
        #docker-directory = /mnt/dockers;
      };
    };
  };
  */

  # For sharing folders with the windows VM
  # Make your local IP static for the VM to never lose the folders
  networking.interfaces.eth0.ipv4.addresses = [ { # for ethernet
    address = "192.168.1.109";
    prefixLength = 24;
  } ];
  #networking.interfaces.wlp0s20f3.ipv4.addresses = [ { # for wifi (see ifconfig), also you have to disconnect eth0 in the GUI # Check https://discourse.nixos.org/t/setting-static-ip-over-wifi/6107
  #  address = "192.168.1.109";
  #  prefixLength = 24;
  #} ];
  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  networking.firewall.allowedTCPPorts = [
    5357 # wsdd
    25565 # For Minecraft
  ];
  networking.firewall.allowedUDPPorts = [
    3702 # wsdd # FOR SAMBA FOLDERS FOR VM
    25565 # For Minecraft
  ];
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = smbnix
      netbios name = smbnix
      security = user 
      #use sendfile = yes
      #max protocol = smb2
      # note: localhost is the ipv6 localhost ::1
      #hosts allow = 192.168.0. 127.0.0.1 localhost
      #hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      hdd-ntfs = {
        path = "/mnt/hdd-ntfs";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        #"force user" = "username";
        #"force group" = "groupname";
      };
      hdd-btrfs = {
        path = "/mnt/hdd-btrfs";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        #"force user" = "username";
        #"force group" = "groupname";
      };
      DataDisk = {
        path = "/mnt/DataDisk";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        #"force user" = "username";
        #"force group" = "groupname";
      };
    };
  };
  services.samba.openFirewall = true;
  # However, for this samba share to work you will need to run `sudo smbpasswd -a <yourusername>` after building your configuration!
  # In windows you can access them in file explorer with `\\192.168.1.xxx` or whatever your local IP is
  # In Windowos you should also map them to a drive to use them in a lot of programs, for this:
  #   - Add a file MapNetworkDriveDataDisk and MapNetworkDriveHdd-ntfs to the folder C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup (to be accessible to every user in every startup):
  #      With these contents respectively:
  #         net use V: "\\192.168.1.109\DataDisk" /p:yes
  #      and
  #         net use V: "\\192.168.1.109\hdd-ntfs" /p:yes
  # Then to have those drives be usable by administrator programs, open a cmd with priviliges and also run both commands above!
}