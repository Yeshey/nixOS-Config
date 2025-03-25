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
      #box64
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

    # boot.binfmt.emulatedSystems = ["i686-linux" "x86_64-linux"];
    #nix.settings.extra-platforms = config.boot.binfmt.emulatedSystems;
    #nix.settings.extra-platforms = ["i686-linux" "x86_64-linux"];

    nixpkgs.overlays = [(self: super: let
      x86pkgs = import pkgs.path { system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in {
      inherit (x86pkgs) steam steam-run;
    })];

    # programs.steam.enable = true;
    # hardware.graphics.enable32Bit = lib.mkForce false;
    # hardware.graphics.enable = lib.mkForce false;

    environment.systemPackages = with pkgs; [
      #steam 
      mybox64
      box86
      steam-run steam-tui steamcmd steam-unwrapped
    ];

/*
You have these bashes rn:
> file /nix/store/iihnyypprr0ygpdcs5wsawks9mznpd88-bash-interactive-5.2p37/bin/bash                                                                                                 18:15:40
/nix/store/iihnyypprr0ygpdcs5wsawks9mznpd88-bash-interactive-5.2p37/bin/bash: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /nix/store/8d9rkvllf04pyz790vk6wd4k8mnc5c64-glibc-2.40-36/lib/ld-linux-aarch64.so.1, BuildID[sha1]=5c9d8b11851246b7766f0a7b3042a8988faad435, for GNU/Linux 3.10.0, not stripped

> file /nix/store/x9d49vaqlrkw97p9ichdwrnbh013kq7z-bash-interactive-5.2p37/bin/bash                                                                                                 18:15:46
/nix/store/x9d49vaqlrkw97p9ichdwrnbh013kq7z-bash-interactive-5.2p37/bin/bash: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /nix/store/nqb2ns2d1lahnd5ncwmn6k84qfd7vx2k-glibc-2.40-36/lib/ld-linux-x86-64.so.2, BuildID[sha1]=34fa0f38a1693296290bec33a571faae527b8535, for GNU/Linux 3.10.0, not stripped


And try and run steam with:
> /nix/store/x9d49vaqlrkw97p9ichdwrnbh013kq7z-bash-interactive-5.2p37/bin/bash -c "box64 /nix/store/2r90fn1idrk09ghra2zg799pff249hmj-steam-unwrapped-1.0.0.81/lib/steam/bin_steam.sh"
 */


    # Export libraries to current path:
    /*
export LD_LIBRARY_PATH="$(for lib in \                                                                                                                                            18:13:30
  glibc \
  gcc-unwrapped.lib \
  libgccjit \
  libpng \
  libpulseaudio \
  libjpeg \
  libvorbis \
  stdenv.cc.cc.lib \
  xorg.libX11 \
  xorg.libXext \
  xorg.libXrandr \
  xorg.libXrender \
  xorg.libXfixes \
  xorg.libXcursor \
  xorg.libXi \
  xorg.libXcomposite \
  xorg.libXtst \
  xorg.libSM \
  xorg.libICE \
  libGL \
  libglvnd \
  vulkan-loader \
  freetype \
  openssl \
  curl \
  zlib \
  dbus \
  ncurses \
  SDL2 \
  ; do nix-build '<nixpkgs>' -A ${lib} --no-out-link; done | xargs -I {} echo -n {}/lib: | sed 's/:$//')"

  # echo $LD_LIBRARY_PATH



  binfmt definition ni nixpkgs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/binfmt.nix
     */

/*
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
    */
  };
}