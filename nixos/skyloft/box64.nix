{ inputs, config, pkgs, lib, ... }:

with lib;
let
  cfg = config.mySystem.box64;
  BOX64_LOG = "1";
  BOX64_DYNAREC_LOG = "0";
  STEAMOS = "1";
  BOX64_VARS= ''
    export STEAMOS=${STEAMOS} # https://github.com/ptitSeb/box64/issues/91#issuecomment-898858125
    export BOX64_LOG=${BOX64_LOG}
    export BOX64_DYNAREC_LOG=${BOX64_DYNAREC_LOG}
    export DBUS_FATAL_WARNINGS=0
  '';

  # Grouped common libraries needed for the FHS environment (64-bit ARM versions)
  steamLibs = with pkgs; [
    glibc glib.out gtk2 gdk-pixbuf pango.out cairo.out fontconfig libdrm libvdpau expat util-linux at-spi2-core libnotify
    gnutls openalSoft udev xorg.libXinerama xorg.libXdamage xorg.libXScrnSaver xorg.libxcb libva gcc-unwrapped.lib libgccjit
    libpng libpulseaudio libjpeg libvorbis stdenv.cc.cc.lib xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXrender xorg.libXfixes
    xorg.libXcursor xorg.libXi xorg.libXcomposite xorg.libXtst xorg.libSM xorg.libICE libGL libglvnd vulkan-loader freetype
    openssl curl zlib dbus ncurses SDL2
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
  ];

  # FHS environment that spawns a bash shell by default, or runs a given command if arguments are provided
  steamFHS = pkgs.buildFHSUserEnv {
    name = "steam-fhs";
    targetPkgs = pkgs: (with pkgs; [
      mybox64 box86 steam-run zenity xdg-utils
    ]) ++ steamLibs;

    multiPkgs = pkgs: steamLibs;

    extraInstallCommands = ''
      mkdir -p $out/lib
      ln -sfn ${pkgs.glibc}/lib/ld-linux-aarch64.so.1 $out/lib/ld-linux-x86-64.so.2
      ln -sfn ${pkgs.zlib}/lib/libz.so.1 $out/lib/libz.so.1.2.13
      ln -sfn ${pkgs.curl.out}/lib/libcurl.so.4 $out/lib/libcurl.so.4

      # Create critical symlinks Steam expects (disabled to avoid errors)
      ln -sfn ${pkgs.glibc}/lib/ld-linux-aarch64.so.1 $out/lib/ld-linux-x86-64.so.2
      ln -sfn ${pkgs.glibc}/lib/ld-linux-aarch64.so.1 $out/lib/ld-linux.so.2
      
      # Steam runtime library workarounds: create necessary directories
      mkdir -p $out/lib32 $out/lib64
      # ln -sfn ${pkgs.libva}/lib/libva.so.2 $out/lib/libva.so.1

      mkdir -p $out/lib $out/lib32 $out/lib64
      
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
      export BOX64_LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu"
      
      # Enable box64/box86 logging if needed
      ${BOX64_VARS}
      
      export GTK_MODULES="xapp-gtk3-module"
      export GDK_BACKEND=x11
      export VK_ICD_FILENAMES="/etc/vulkan/icd.d/radeon_icd.x86_64.json"

      export BOX64_EMULATED_LIBS="libmpg123.so.0"
      export BOX64_TRACE_FILE="stderr"
      export BOX86_TRACE_FILE="stderr"
      export STEAM_RUNTIME_PREFER_HOST_LIBRARIES="0"
      # Add sniper runtime path
      export STEAM_RUNTIME_SCOUT="/home/yeshey/.local/share/Steam/ubuntu12_32/steam-runtime/sniper"

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
  exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 ${pkgs.bashx86}/bin/bash "$@"
'';
in {
  options.mySystem.box64.enable = mkEnableOption "box64";

  config = mkIf cfg.enable {

    # you made this comment in nixos discourse: https://discourse.nixos.org/t/how-to-install-steam-x86-64-on-a-pinephone-aarch64/19297/7?u=yeshey
    
    # Uncomment these lines if you need to set extra platforms for binfmt:
    # boot.binfmt.emulatedSystems = ["i686-linux" "x86_64-linux"];
    # nix.settings.extra-platforms = config.boot.binfmt.emulatedSystems;
    # nix.settings.extra-platforms = ["i686-linux" "x86_64-linux"];

    nixpkgs.overlays = [
      (self: super: let
        x86pkgs = import pkgs.path {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      in {
        inherit (x86pkgs) steam steam-run;
        bashx86 = x86pkgs.bashInteractive;
        steamx86 = x86pkgs.steam-unwrapped;
      })
    ];

    environment.systemPackages = with pkgs; let 

      steamx86Wrapper = pkgs.writeScriptBin "box64-bashx86-steamx86-wrapper" ''
        #!${pkgs.bash}/bin/sh
        ${BOX64_VARS}
        exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 \
          ${pkgs.bashx86}/bin/bash ${steamx86}/lib/steam/bin_steam.sh \
          -no-cef-sandbox \
          -cef-disable-gpu \
          -cef-disable-gpu-compositor \
          -system-composer \
          steam://open/minigameslist "$@"
      '';

    in [
      # steam-related packages
      box64BashWrapper
      steamx86
      steamx86Wrapper
      steamFHS
      mybox64
      box86
      bashx86 #(now this one appears with whereis bash)
      # additional steam-run tools
      # steam-tui steamcmd steam-unwrapped
    ];

    boot.binfmt.registrations = 
    let 

    in {
      first_box64 =
      {
        #interpreter = "${pkgs.mybox64}/bin/mybox64";
        interpreter = "${box64BashWrapper}/bin/box64-bashx86-wrapper";
        # x86_64 binaries: magic from nixpkgs “x86_64-linux”
        magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
        mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
      };
      second_box64 = {
        #interpreter = "${pkgs.mybox64}/bin/mybox64";
        interpreter = "${box64BashWrapper}/bin/box64-bashx86-wrapper";
        # i686 binaries: magic from nixpkgs “i686-linux”
        magicOrExtension = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x06\x00'';
        mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
      };
    };

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