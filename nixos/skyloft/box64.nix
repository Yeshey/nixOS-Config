# made a box64 issue https://github.com/ptitSeb/box64/issues/2478
{ inputs, config, pkgs, lib, ... }:

with lib;
let 
  # Grouped common libraries needed for the FHS environment (64-bit ARM versions)
  steamLibs = with pkgs; [
    glibc glib.out gtk2 gdk-pixbuf pango.out cairo.out fontconfig libdrm libvdpau expat util-linux at-spi2-core libnotify
    gnutls openalSoft udev xorg.libXinerama xorg.libXdamage xorg.libXScrnSaver xorg.libxcb libva gcc-unwrapped.lib libgccjit
    libpng libpulseaudio libjpeg libvorbis stdenv.cc.cc.lib xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXrender xorg.libXfixes
    xorg.libXcursor xorg.libXi xorg.libXcomposite xorg.libXtst xorg.libSM xorg.libICE libGL libglvnd vulkan-loader freetype
    openssl curl zlib dbus-glib ncurses SDL2
    vulkan-headers vulkan-loader vulkan-tools
    libva mesa.drivers
    ncurses5 ncurses6 ncurses
    pkgs.curl.out
    libcef # (https://github.com/ptitSeb/box64/issues/1383)?

    libdbusmenu       # For libdbusmenu-glib.so.4 and libdbusmenu-gtk.so.4
    xcbutilxrm       # XCB utilities
    xorg.libxcb
    xorg.xcbutilkeysyms
    sbclPackages.cl-cairo2-xlib        # X11-specific Cairo components
    pango         # X11-specific Pango components
    gtk3-x11          # Explicitly include GTK2 X11 libraries

    libmpg123
    ibus-engines.libpinyin
    libnma
    nss
    nspr

    # Keep existing libraries and add:
    libudev-zero
    libusb1 ibus-engines.kkc gtk3

    xdg-utils
    vulkan-validation-layers vulkan-headers

    # https://github.com/ptitSeb/box64/issues/1780#issuecomment-2627480114
    zenity dbus libnsl libunity pciutils openal
    passt

    # For Heroic
    cups                  # For libcups
    alsa-lib              # For libasound
    libxslt               # For libxslt
    zstd                  # For libzstd
    xorg.libxshmfence          # For libxshmfence
    avahi                 # For libavahi
    xorg.libpciaccess          # For libpciaccess
    elfutils              # For libelf
    lm_sensors            # For libsensors
    libffi                # For libffi
    flac                  # For libFLAC
    libogg                # For libogg
    libbsd                # For libbsd
    libxml2               # For xml symbols
    llvmPackages.libllvm  # For libLLVM
    libllvm

    libdrm.out
    unstable.libgbm
    unstable.libgbm.out

    libselinux
    libcap libcap_ng libcaption

    gmp
    gmpxx 
    libgmpris
  ];
in
let
  cfg = config.mySystem.box64;
  BOX64_LOG = "1";
  BOX64_DYNAREC_LOG = "0";
  STEAMOS = "1";
  STEAM_RUNTIME = "1";
  BOX64_VARS= ''
    export BOX64_DLSYM_ERROR=1
    export BOX64_TRANSLATE_NOWAIT=1
    export BOX64_NOBANNER=1
    export STEAMOS=${STEAMOS} # https://github.com/ptitSeb/box64/issues/91#issuecomment-898858125
    export BOX64_LOG=${BOX64_LOG}
    export BOX64_DYNAREC_LOG=${BOX64_DYNAREC_LOG}
    export DBUS_FATAL_WARNINGS=1
    export STEAM_RUNTIME=${STEAM_RUNTIME}
    export BOX64_LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") steamLibs}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu" # didn't help
    export LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") steamLibs}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu" # didn't help
    export DBUS_FATAL_WARNINGS=0
    BOX64_AVX=0 # didnt help https://github.com/ptitSeb/box64/issues/1691
  '';

  # FHS environment that spawns a bash shell by default, or runs a given command if arguments are provided
  steamFHS = pkgs.buildFHSUserEnv {
    name = "steam-fhs";
    targetPkgs = pkgs: (with pkgs; [
      mybox64 box86 steam-run zenity xdg-utils
      vulkan-validation-layers vulkan-headers
      libva-utils
    ]) ++ steamLibs;

    multiPkgs = pkgs: steamLibs;

    extraInstallCommands = ''
      mkdir -p $out/lib
      ln -sfn ${pkgs.glibc}/lib/ld-linux-aarch64.so.1 $out/lib/ld-linux-x86-64.so.2
      ln -sfn ${pkgs.zlib}/lib/libz.so.1 $out/lib/libz.so.1.2.13
      ln -sfn ${pkgs.curl.out}/lib/libcurl.so.4 $out/lib/libcurl.so.4

      # Create Steam Runtime directory structure
      #mkdir -p $out/steam-runtime/sniper
      #ln -sfn ${pkgs.x86.steam-unwrapped}/share/steam/steam-runtime $out/steam-runtime

      # Fix ncurses symlinks
      ln -sfn ${pkgs.ncurses5}/lib/libncursesw.so.6 $out/lib/libtinfo.so.6
      # ln -sfn ${pkgs.ncurses5}/lib/libncursesw.so.6 $out/lib32/libtinfo.so.6

      # Add missing Vulkan library links
      ln -sfn ${pkgs.vulkan-loader}/lib/libvulkan.so.1 $out/lib/libvulkan.so.1
      ln -sfn ${pkgs.vulkan-loader}/lib/libvulkan.so $out/lib/libvulkan.so
      
      # Fix DRI3 authentication
      ln -sfn ${pkgs.libdrm}/lib/libdrm.so.2 $out/lib/libdrm.so.2
      ln -sfn ${pkgs.libglvnd}/lib/libGLX.so.0 $out/lib/libGLX.so.0

      # Create critical symlinks Steam expects (disabled to avoid errors)
      ln -sfn ${pkgs.glibc}/lib/ld-linux-aarch64.so.1 $out/lib/ld-linux-x86-64.so.2
      ln -sfn ${pkgs.glibc}/lib/ld-linux-aarch64.so.1 $out/lib/ld-linux.so.2
      
      # Steam runtime library workarounds: create necessary directories
      mkdir -p $out/lib32 $out/lib64
      # ln -sfn ${pkgs.libva}/lib/libva.so.2 $out/lib/libva.so.1

      mkdir -p $out/lib $out/lib32 $out/lib64
      
      # Create a dummy passt script so that child process "passt" is found
      mkdir -p $out/bin
      echo '#!/bin/sh
      exit 0' > $out/bin/passt
      chmod +x $out/bin/passt

      # Force use of Steam Runtime's libcurl
      ln -sfn "$STEAM_RUNTIME/lib/i386-linux-gnu/libcurl.so.4" "$out/lib/libcurl.so.4"
      ln -sfn "$STEAM_RUNTIME/lib/x86_64-linux-gnu/libcurl.so.4" "$out/lib64/libcurl.so.4"
      
      # Workaround for libtinfo
      ln -sfn ${pkgs.ncurses5}/lib/libncursesw.so.6 $out/lib/libtinfo.so.6
      ln -sfn ${pkgs.ncurses5}/lib/libncursesw.so.6 $out/lib32/libtinfo.so.6
    '';

    runScript = ''
      # Set up environment variables for box64 and libraries
      export STEAM_EXTRA_COMPAT_TOOLS_PATHS="${pkgs.mybox64}/bin"
      export BOX64_PATH="${pkgs.mybox64}/bin"
      
      export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json"
      export VK_LAYER_PATH="${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d"
      export __GLX_VENDOR_LIBRARY_NAME="mesa"
      # export MESA_LOADER_DRIVER_OVERRIDE="zink"

      # Enable box64/box86 logging if needed
      ${BOX64_VARS}
      
      export GTK_MODULES="xapp-gtk3-module"
      export GDK_BACKEND=x11
      export VK_ICD_FILENAMES="/etc/vulkan/icd.d/radeon_icd.x86_64.json"

      export BOX64_EMULATED_LIBS="libmpg123.so.0"
      export BOX64_TRACE_FILE="stderr"
      #export BOX86_TRACE_FILE="stderr"

      #BOX64_TRACE_FILE=/tmp/steamwebhelper-%pid.txt
      BOX64_SHOWSEGV=1
      BOX64_DLSYM_ERROR=1

      export STEAM_RUNTIME=${STEAM_RUNTIME}
      # Add sniper runtime path
      # export STEAM_RUNTIME_SCOUT="/home/yeshey/.local/share/Steam/ubuntu12_32/steam-runtime/sniper"
      export STEAM_RUNTIME_SCOUT="/home/yeshey/.local/share/Steam/ubuntu12_32/steam-runtime"

      # Force use of FHS environment's libraries
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$out/lib:$out/lib32"
      
      # If no arguments are provided, spawn an interactive bash shell.
      # Otherwise, run the provided command.
      if [ "$#" -eq 0 ]; then
        exec ${pkgs.bashInteractive}/bin/bash
      else
        exec "$@"
      fi
    '';
  };


in 
let 
box64BashWrapper = pkgs.writeScriptBin "box64-bashx86-wrapper" ''
  #!${pkgs.bash}/bin/sh
  ${BOX64_VARS}
  export BOX64_TRACE_FILE="stderr"
  export BOX86_TRACE_FILE="stderr"

  exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 ${pkgs.x86.bash}/bin/bash "$@"
'';
box64Wrapper = pkgs.writeScriptBin "box64-wrapper" ''
  #!${pkgs.bash}/bin/sh
  ${BOX64_VARS}
  export BOX64_TRACE_FILE="stderr"
  #export BOX86_TRACE_FILE="stderr"

  #BOX64_TRACE_FILE=/tmp/steamwebhelper-%pid.txt
  BOX64_SHOWSEGV=1
  BOX64_DLSYM_ERROR=1

  exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 "$@"
'';
in {
  options.mySystem.box64.enable = mkEnableOption "box64";

  config = mkIf cfg.enable {

    # Needed to allow installing x86 packages, otherwise: error: i686 Linux package set can only be used with the x86 family
    nixpkgs.overlays = [
      (self: super: let
        x86pkgs = import pkgs.path {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      in {
        inherit (x86pkgs) steam-run;
        # steam steam-run
        #steam steam-run;
        #bashx86 = x86pkgs.bashInteractive;
        #steamx86 = x86pkgs.steam-unwrapped;
      })
    ];

    # Add these env variables to /home/yeshey/.local/share/Steam/steam.sh to get more logs when it downloaads the stuffs
    #export STEAM_DEBUG=1  # Enables set -x in steam.sh
    #export STEAM_LOG=1    # Additional Steam logging

    # you made this comment in nixos discourse: https://discourse.nixos.org/t/how-to-install-steam-x86-64-on-a-pinephone-aarch64/19297/7?u=yeshey
    
    # Uncomment these lines if you need to set extra platforms for binfmt:
    # boot.binfmt.emulatedSystems = ["i686-linux" "x86_64-linux"];
    # nix.settings.extra-platforms = config.boot.binfmt.emulatedSystems;
    nix.settings.extra-platforms = ["i686-linux" "x86_64-linux"];
    nixpkgs.config.allowUnsupportedSystem = true;


    environment.systemPackages = with pkgs; let 

      steamx86Wrapper = pkgs.writeScriptBin "box64-bashx86-steamx86-wrapper" ''
        #!${pkgs.bash}/bin/sh
        ${BOX64_VARS}
        # Fix Steam Runtime paths
        export STEAM_RUNTIME=1
        export STEAM_RUNTIME_SCOUT="$STEAM_RUNTIME"
        export STEAM_RUNTIME_SNIER="$STEAM_RUNTIME/sniper"
        
        # Create required runtime directory
        mkdir -p "$STEAM_RUNTIME_SNIER"
        export STEAM_RUNTIME_SCOUT="$HOME/.local/share/Steam/ubuntu12_32/steam-runtime"
        exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 \
          ${pkgs.x86.bash}/bin/bash ${pkgs.x86.steam-unwrapped}/lib/steam/bin_steam.sh \
          -no-cef-sandbox \
          -cef-disable-gpu \
          -cef-disable-gpu-compositor \
          -system-composer \
          -srt-logger-opened \ 
          steam://open/minigameslist "$@"
      '';

      heroicx86Wrapper = pkgs.writeScriptBin "box64-bashx86-heroicx86-wrapper" ''
        #!${pkgs.bash}/bin/sh
        ${BOX64_VARS}

        exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 \
          ${pkgs.x86.bash}/bin/bash ${pkgs.x86.heroic-unwrapped}/bin/heroic
      '';

      steamcmdx86Wrapper = pkgs.writeScriptBin "box64-bashx86-steamcmdx86-wrapper" ''
        #!${pkgs.bash}/bin/sh
        ${BOX64_VARS}

        exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 \
          ${pkgs.x86.bash}/bin/bash ${pkgs.x86.steamcmd}/bin/steamcmd
      # '';

    in [
      # steam-related packages
      box64Wrapper
      box64BashWrapper
      unstable.fex # idfk man
      #steamx86
      x86.steam-unwrapped
      x86.heroic-unwrapped
      # steamcmdx86Wrapper
      # pkgs.x86.steamcmd
      heroicx86Wrapper
      steamx86Wrapper
      steamFHS
      mybox64
      x86.bash #(now this one appears with whereis bash)
      muvm
      # additional steam-run tools
      # steam-tui steamcmd steam-unwrapped
    ];

    boot.binfmt.registrations = {
      i386-linux = {
        interpreter = "${box64Wrapper}/bin/box64-wrapper";
        magicOrExtension = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00'';
        mask             = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
      };

      x86_64-linux = {
        interpreter = "${box64Wrapper}/bin/box64-wrapper";
        magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
        mask             = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
      };
    };


    # boot.binfmt.registrations = # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/binfmt.nix
    # let 

    # in {
    #   first_box64 =
    #   {
    #     #interpreter = "${pkgs.mybox64}/bin/mybox64";
    #     interpreter = "${box64Wrapper}/bin/box64-wrapper";
    #     # x86_64 binaries: magic from nixpkgs “x86_64-linux”
    #     magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
    #     mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
    #   };
    #   i686 = {
    #     interpreter = "${box64Wrapper}/bin/box64-wrapper";
    #     magicOrExtension = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00'';
    #     mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff'';
    #   };
    #   # second_box64 = {
    #   #   #interpreter = "${pkgs.mybox64}/bin/mybox64";
    #   #   interpreter = "${box64Wrapper}/bin/box64-wrapper";
    #   #   # i686 binaries: magic from nixpkgs “i686-linux”
    #   #   magicOrExtension = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x06\x00'';
    #   #   mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
    #   # };
    # };

  # with this you can run steam-fhs, and the following command:
  # TEAMOS=1 BOX64_LOG=0 mybox64 /nix/store/x9d49vaqlrkw97p9ichdwrnbh013kq7z-bash-interactive-5.2p37/bin/bash /nix/store/2r90fn1idrk09ghra2zg799pff249hmj-steam-unwrapped-1.0.0.81/lib/steam/bin_steam.sh

/*
# Using this command to start steam
/nix/store/x9d49vaqlrkw97p9ichdwrnbh013kq7z-bash-interactive-5.2p37/bin/bash -c "BOX64_LOG=0 mybox64 /nix/store/x9d49vaqlrkw97p9ichdwrnbh013kq7z-bash-interactive-5.2p37/bin/bash /nix/store/2r90fn1idrk09ghra2zg799pff249hmj-steam-unwrapped-1.0.0.81/lib/steam/bin_steam.sh"

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
export LD_LIBRARY_PATH="$(for lib in \                                                                                                                                                            01:39:42
  glibc glib.out gtk2 gdk-pixbuf pango.out cairo.out \
  fontconfig libdrm libvdpau expat util-linux \
  at-spi2-core libnotify gnutls openalSoft udev \
  xorg.libXinerama xorg.libXdamage xorg.libXScrnSaver \
  xorg.libxcb libva gcc-unwrapped.lib libgccjit \
  libpng libpulseaudio libjpeg libvorbis stdenv.cc.cc.lib \
  xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXrender \
  xorg.libXfixes xorg.libXcursor xorg.libXi xorg.libXcomposite \
  xorg.libXtst xorg.libSM xorg.libICE libGL libglvnd \
  vulkan-loader freetype openssl curl zlib dbus ncurses SDL2 \
  ; do nix-build '<nixpkgs>' -A ${lib} --no-out-link; done \
  | xargs -I {} echo -n {}/lib: | sed 's/:$//')\
:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu\
:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu\
:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib\
:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib"

  # echo $LD_LIBRARY_PATH



  binfmt definition ni nixpkgs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/binfmt.nix
     */
  };
}