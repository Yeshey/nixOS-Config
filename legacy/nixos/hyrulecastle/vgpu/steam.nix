# Done with https://www.kimi.com
# because steam is broken with older nvidia driver
# Apparantly the moment you boot the vgpu-patched driver the i686 OpenGL stack that Steam downloads is forced to use the NVIDIA 32-bit userspace libraries that come with that driver.
# Those libraries are not part of the normal NixOS closure – they are copied in by the Steam runtime helper and they do not get rebuilt when you update util-linux. Consequently they still carry the old DT_NEEDED tag MOUNT_2_39, while the glib2 that is already in the runtime (built against a newer util-linux) expects MOUNT_2_40

{ config, pkgs, lib, ... }:

let
  utilLinux32 = pkgs.pkgsi686Linux.util-linux;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      steam = prev.steam.override {
        extraPkgs = p: [ utilLinux32 ];
      };
    })
  ];

  programs.steam.enable = true;
}