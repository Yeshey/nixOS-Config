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
# Surface is underpowered, use this command in the more powerfull machine to build:
# sudo nixos-rebuild --flake .#surface --target-host root@192.168.1.115 --build-host localhost switch
#
# Or use this one in the surface:
# sudo nixos-rebuild --flake .#surface --build-host root@192.168.1.102 switch

{ config, pkgs, user, location, lib, dataStoragePath, ... }:

#let
 #Steam needs this env variable to display in the right scalling (https://www.reddit.com/r/NixOS/comments/qha9t5/comment/hid3w3z/)
#  steam-s = pkgs.writeShellScriptBin "steam-s" ''
#    export GDK_SCALE=2
#    exec -a "$0" ${pkgs.steam}/bin/steam
#    # exec ${pkgs.steam} "$@"
#  '';
#in

let
    # Wrapper to run steam with env variable GDK_SCALE=2 to scale correctly
    # nixOS wiki on wrappers: https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages
    # Reddit: https://www.reddit.com/r/NixOS/comments/qha9t5/comment/hid3w3z/
    steam-scalled = pkgs.runCommand "steam" {
      buildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir $out
      # Link every top-level folder from pkgs.steam to our new target
      ln -s ${pkgs.steam}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${pkgs.steam}/bin/* $out/bin
      # Except the steam binary
      rm $out/bin/steam
      # Because we create this ourself, by creating a wrapper
      makeWrapper ${pkgs.steam}/bin/steam $out/bin/steam \
        --set GDK_SCALE 2 \
        --add-flags "-t"
    '';

    stremio-scalled = pkgs.runCommand "stremio" {
      buildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir $out
      # Link every top-level folder from pkgs.stremio to our new target
      ln -s ${pkgs.stremio}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${pkgs.stremio}/bin/* $out/bin
      # Except the stremio binary
      rm $out/bin/stremio
      # Because we create this ourself, by creating a wrapper
      makeWrapper ${pkgs.stremio}/bin/stremio $out/bin/stremio \
        --set QT_AUTO_SCREEN_SCALE_FACTOR 1 \
        --add-flags "-t"
    '';
in
{
  imports =                                     # For now, if applying to other system, swap files
    [(import ./hardware-configuration.nix)];    # Current system hardware config @ /etc/nixos/hardware-configuration.nix


  # Manage Temperature, prevent throttling
  # https://github.com/linux-surface/linux-surface/issues/221
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
            --config-file ${location}/hosts/surface/configFiles/thermal-conf.xml \
        '';

  # swap in ext4:
  swapDevices = [ 
    {
      device = "/swapfile";
      priority = 0; # Higher numbers indicate higher priority.
      size = 10*1024;
      options = [ "nofail"];
    }
  ];
  zramSwap = { # zram only made things slwo whenever there were animations when the thermald temperature threshold was set too low (61069)
    enable = true;
    algorithm = "zstd";
  };

  #     ___            __ 
  #    / _ )___  ___  / /_
  #   / _  / _ \/ _ \/ __/
  #  /____/\___/\___/\__/  

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # trying to activate wayland support for vivaldi?
  nixpkgs.config.vivaldi.commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";

  # GNOME Desktop (uses wayland)
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    # Make Surface Touchpad Work:
    desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.peripherals.touchpad]
      click-method='default'
    '';
  };

  # A multi-touch gesture recognizer
  # services.touchegg.enable = true; # only for X11

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    stremio-scalled
    # iptsd
    
    # Games
    steam-scalled
    
  ];

}
