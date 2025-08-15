# thanks to https://github.com/MakiseKurisu/nixos-config/blob/main/modules/nvidia-vgpu.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # To pass the whole hdd disk, hide it from nixOS, if both write at the same time, it gets corrupted
  fileSystems."/mnt/hdd-ntfs" = lib.mkForce {
    device = "/dev/disk/by-label/hdd-ntfs";
    fsType = "none";
    options = [ "noauto" "nofail" "x-gvfs-hide" ];
  };
  fileSystems."/mnt/hdd-btrfs" = lib.mkForce {
    device = "/dev/disk/by-label/hdd-btrfs";
    fsType = "none";
    options = [ "noauto" "nofail" "x-gvfs-hide" ];
  };
  fileSystems."/mnt/hdd-ext4" = lib.mkForce {
    device = "/dev/disk/by-label/hdd-ext4";
    fsType = "none";
    options = [ "noauto" "nofail" "x-gvfs-hide" ];
  };

  # Samba
  # The VM by default sees the host at 192.168.122.1 
  services.samba-wsdd.enable = true;
  networking.firewall.allowedTCPPorts = [
    5357 # wsdd
  ];
  networking.firewall.allowedUDPPorts = [
    3702 # wsdd
  ];
  services.samba = {
    enable = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      yesheyHome = {
        path = "/home/yeshey";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";

        "force user" = "yeshey";
        "force group" = "users";
      };
    };
  };
  networking.firewall.allowPing = true;
  services.samba.openFirewall = true;

}

