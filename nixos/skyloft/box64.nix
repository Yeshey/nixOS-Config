{ inputs, config, pkgs, lib, ... }:

with lib;
let
  cfg = config.mySystem.box64;
  
  # Use x86_64 packages via cross-compilation
  pkgsx86 = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnsupportedSystem = true;
    config.allowUnfree = true;
    overlays = [
      (self: super: {
        # Force 32-bit libs to come from x86_64 package set
        pkgsi686Linux = super.pkgsi686Linux;
      })
    ];
  };

  # Common libraries needed for Steam
  steamLibs = with pkgsx86; [
    # 64-bit libraries
    glibc
    gcc-unwrapped.lib
    libgccjit
    libpng
    libpulseaudio
    libjpeg
    libpng
    libvorbis
    stdenv.cc.cc.lib
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
    xorg.libXrender
    xorg.libXfixes
    xorg.libXcursor
    xorg.libXi
    xorg.libXcomposite
    xorg.libXtst
    xorg.libSM
    xorg.libICE
    libGL
    libglvnd
    vulkan-loader
    freetype
    openssl
    curl
    zlib
    dbus
    ncurses
    SDL2
    # 32-bit libraries
    (pkgsi686Linux.glibc)
    (pkgsi686Linux.gcc-unwrapped.lib)
    (pkgsi686Linux.libpulseaudio)
    (pkgsi686Linux.libjpeg)
    (pkgsi686Linux.xorg.libX11)
    (pkgsi686Linux.xorg.libXext)
    (pkgsi686Linux.xorg.libXrandr)
    (pkgsi686Linux.libGL)
    (pkgsi686Linux.vulkan-loader)
  ];

  # FHS environment for Steam
  steamFHS = pkgs.buildFHSUserEnv {
    name = "steam-fhs";
    targetPkgs = pkgs: (with pkgsx86; [
      box64
      steamPackages.steam
      # steamPackages.steam-runtime
    ]) ++ steamLibs;

    multiPkgs = pkgs: steamLibs;

    extraInstallCommands = ''
      mkdir -p $out/etc/ld.so.conf.d
      echo "${pkgsx86.glibc}/lib" > $out/etc/ld.so.conf.d/glibc.conf
      echo "${pkgsx86.glibc}/lib32" >> $out/etc/ld.so.conf.d/glibc.conf
    '';

    runScript = "steam";
  };

in {
  options.mySystem.box64.enable = mkEnableOption "box64";

  config = mkIf cfg.enable {
    # Required for OpenGL/Vulkan
    #hardware.opengl = {
    #  enable = true;
    #  driSupport32Bit = true;
    #};

    # Binfmt configuration for Box64
    boot.binfmt.registrations.box64 = {
      interpreter = "${steamFHS}/bin/steam-fhs";
      magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
      mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
    };

    environment.systemPackages = [ steamFHS ];

    # Required environment variables
    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/usr/lib/steam";
      LD_LIBRARY_PATH = "${pkgsx86.glibc}/lib:${pkgsx86.glibc}/lib32";
    };

    # Needed for Steam runtime
    systemd.extraConfig = ''
      DefaultLimitNOFILE=1048576
    '';
  };
}