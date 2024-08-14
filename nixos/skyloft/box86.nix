{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.mySystem.box86;

  # Okay actually use this: https://discourse.nixos.org/t/best-way-to-define-common-fhs-environment/25930/3
  # and this: https://github.com/NixOS/nixpkgs/blob/3374c1ab484d602e7b0f704e276253d682b9f2d0/pkgs/games/anki/bin.nix#L53
  # to build a new FHS environment

  commonPackages = [
    pkgs.SDL2 pkgs.SDL2_image pkgs.SDL2_mixer pkgs.SDL2_ttf
    pkgs.openal pkgs.libpng pkgs.fontconfig pkgs.xorg.libXcomposite pkgs.bzip2
    pkgs.xorg.libXtst pkgs.xorg.libSM pkgs.xorg.libICE pkgs.libGL     
    pkgs.mesa pkgs.libglvnd pkgs.libGLU pkgs.xorg.libXinerama pkgs.xorg.libXdamage pkgs.ibus pkgs.ncurses
  ] ++ [
    pkgs.libsigcxx pkgs.zlib pkgs.xorg.libX11 pkgs.xorg.libXext pkgs.xorg.libXrender pkgs.xorg.libXrandr
    pkgs.xorg.libXcursor pkgs.xorg.libXfixes pkgs.xorg.libXi pkgs.xorg.libxcb pkgs.libpulseaudio pkgs.dbus
    pkgs.vulkan-loader pkgs.openssl pkgs.curl pkgs.freetype pkgs.expat pkgs.libjpeg
    pkgs.libxcrypt pkgs.util-linux # util-linux provides libuuid
    pkgs.libcap
  ];

  box86FHS = pkgs.pkgsCross.armv7l-hf-multiplatform.buildFHSUserEnv {
    name = "box86-fhs";
    targetPkgs = pkgs: [
      pkgs.mybox86
      pkgs.glibc
    ] ++ commonPackages;

    extraInstallCommands = ''
      mkdir -p $out/etc/ld.so.conf.d
      echo "/usr/lib32" > $out/etc/ld.so.conf.d/steam.conf
      echo "/usr/lib/i386-linux-gnu/mesa" >> $out/etc/ld.so.conf.d/steam.conf
      # ${pkgs.glibc.bin}/bin/ldconfig -r $out
    '';

    #runScript = ''
    #  export LD_LIBRARY_PATH=/usr/lib32:/usr/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu/mesa:$LD_LIBRARY_PATH
    #  exec "$@"
    #'';
  };

  box64FHS = pkgs.buildFHSUserEnv {
    name = "box64-fhs";
    targetPkgs = pkgs: [
      pkgs.box64
      pkgs.glibc
    ] ++ commonPackages;

    postBuild = ''
      mkdir -p $out/etc/ld.so.conf.d
      echo "/usr/lib32" > $out/etc/ld.so.conf.d/steam.conf
      echo "/usr/lib/x86_64-linux-gnu" >> $out/etc/ld.so.conf.d/steam.conf
      ${pkgs.glibc.bin}/bin/ldconfig -r $out
    '';

    #runScript = ''
    #  export LD_LIBRARY_PATH=/usr/lib:/usr/lib32:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
    #  exec "$@"
    #'';
  };

  # the box86 package commit https://github.com/NixOS/nixpkgs/pull/174113
in
{
  imports = [
    
  ];
  
  options.mySystem.box86 = {
    enable = mkEnableOption "box86";
  };

  config = let 

    # Import the specific nixpkgs version
    nixpkgsVersion = import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-22.05.tar.gz";
      sha256 = "sha256:1lsrlgx4rg2wqxrz5j7kzsckgk4ymvr1l77rbqm1zxap6hg07dxf";
    }) {
      system = "x86_64-linux";
    };

  in lib.mkIf cfg.enable {

    # boot.binfmt.emulatedSystems = [ "armv7l-linux" "x86_64-linux" ];
    # boot.binfmt.registrations.armv7l-linux.preserveArgvZero = true;
/*
    #nix.settings.extra-platforms = "armv7l-linux";
    nixpkgs.config = {
      allowUnsupportedSystem = true;
      extra-platforms = [ "x86_64-linux" ];
    };

    # Override the pkgs with the specific nixpkgs version
    nixpkgs.overlays = [
      (final: prev: {
        steam = nixpkgsVersion.steam;
      })
    ];

    hardware.opengl.driSupport32Bit = lib.mkForce false;
    programs.steam.enable = true;
*/
/*
    containers.gaming.autoStart = true;
    containers.gaming =
      { config =
          { config, pkgs, ... }:
          { services.postgresql.enable = true;
          services.postgresql.package = pkgs.postgresql_14;
          };
      }; */

    # https://github.com/NixOS/nixpkgs/pull/174113
    # Jogos que funcionam: https://box86.org/app/

    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/binfmt.nix
    boot.binfmt.registrations = {
      box86 = {
        # i686-linux
        interpreter = "${box86FHS}/bin/box86-fhs"; # box86-fhs?
        magicOrExtension = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x06\x00'';
        mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
      };
      box64 = {
        # x86_64-linux
        interpreter = "${box64FHS}/bin/box64-fhs"; #box64-fhs
        magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
        mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
      };
    };
    #nix.settings.extra-platforms = ["armv7l-linux"];
    # Add box86-fhs and box64-fhs to system packages so they are available in the shell
    environment.systemPackages = with pkgs; [
      box86FHS # box86-fhs
      box64FHS # box64-fhs
      pkgs.mybox86
      pkgs.box64
    ];
    #hardware = {
      # opengl.driSupport32Bit = true;
    #  opengl.setLdLibraryPath = true; 
    #  pulseaudio.support32Bit = true;
    #};

  };
}
