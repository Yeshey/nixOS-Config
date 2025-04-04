# made a box64 issue https://github.com/ptitSeb/box64/issues/2478
{ inputs, config, pkgs, lib, ... }:

with lib;
let 
  # Grouped common libraries needed for the FHS environment (64-bit ARM versions)
  steamLibs = with pkgs; [
    glibc glib.out gtk2 gdk-pixbuf pango.out cairo.out fontconfig libdrm libvdpau expat util-linux at-spi2-core libnotify
    gnutls openalSoft udev xorg.libXinerama xorg.libXdamage xorg.libXScrnSaver xorg.libxcb libva gcc-unwrapped.lib libgccjit
    libpng libpulseaudio libjpeg libvorbis stdenv.cc.cc.lib xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXrender xorg.libXfixes
    xorg.libXcursor xorg.libXi xorg.libXcomposite xorg.libXtst xorg.libSM xorg.libICE libGL libglvnd freetype
    openssl curl zlib dbus-glib ncurses
    
    libva mesa.drivers
    ncurses5 ncurses6 ncurses
    pkgs.curl.out
    libcef # (https://github.com/ptitSeb/box64/issues/1383)?

    libdbusmenu       # For libdbusmenu-glib.so.4 and libdbusmenu-gtk.so.4 # causing Error: detected mismatched Qt dependencies: when compiled for steamLibsI686
    xcbutilxrm       # XCB utilities
    xorg.xcbutilkeysyms
    sbclPackages.cl-cairo2-xlib        # X11-specific Cairo components
    pango         # X11-specific Pango components
    gtk3-x11          # Explicitly include GTK2 X11 libraries

    libmpg123
    ibus-engines.libpinyin
    libnma
    libnma-gtk4
    libappindicator libappindicator-gtk3 libappindicator-gtk2
    nss
    nspr

    # Keep existing libraries and add:
    libudev-zero
    libusb1 ibus-engines.kkc gtk3

    xdg-utils
    
    # for vulkan? https://discourse.nixos.org/t/setting-up-vulkan-for-development/11715/3
    # old: vulkan-validation-layers vulkan-headers
    dotnet-sdk_8
    glfw
    freetype
    vulkan-headers
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools        # vulkaninfo
    shaderc             # GLSL to SPIRV compiler - glslc
    renderdoc           # Graphics debugger
    tracy               # Graphics profiler
    vulkan-tools-lunarg # vkconfig

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

    libcap libcap_ng libcaption

    gmp
    gmpxx 
    libgmpris

    SDL2
    SDL2_image
    SDL2_mixer
    SDL2_ttf
    bzip2

    SDL sdl3 SDL2 sdlpop SDL_ttf SDL_net SDL_gpu SDL_gfx sdlookup SDL2_ttf SDL2_net SDL2_gfx SDL_sound SDL_sixel 
    SDL_mixer SDL_image SDL_Pango sdl-jstest SDL_compat SDL2_sound SDL2_mixer SDL2_image SDL2_Pango SDL_stretch 
    SDL_audiolib SDL2_mixer_2_0 SDL2_image_2_6 SDL2_image_2_0

    #libstdcxx5
    libcdada
    libgcc

    swiftshader # CPU implementation of vulkan

    libGL
    xapp
    libunity
    libselinux            # libselinux

    python3 wayland wayland-protocols patchelf libGLU
  ];
  steamLibsI686 = with pkgs.pkgsCross.gnu32; [
    glibc
    glib.out
    gtk2
    gdk-pixbuf
    cairo.out
    fontconfig
    libdrm
    libvdpau
    expat
    util-linux
    at-spi2-core
    libnotify
    gnutls
    openalSoft
    udev
    xorg.libXinerama
    xorg.libXdamage
    xorg.libXScrnSaver
    xorg.libxcb
    libva
    libpng
    libpulseaudio
    libjpeg
    libvorbis
    stdenv.cc.cc.lib
    xorg.libX11
    xorg.libXext
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
    freetype
    openssl
    curl
    zlib
    dbus-glib
    ncurses
    vulkan-headers
    vulkan-loader
    vulkan-tools
    mesa.drivers
    ncurses5
    ncurses6
    pkgs.curl.out
    libdbusmenu
    xcbutilxrm
    xorg.xcbutilkeysyms
    # pango pango.out SDL2_Pango SDL_Pango # pango compile error
    gtk3-x11
    libmpg123
    # ibus-engines.libpinyin Error libpiny
    libnma
    libnma-gtk4
    libappindicator
    libappindicator-gtk3
    libappindicator-gtk2
    nss
    nspr
    libudev-zero
    libusb1
    # ibus-engines.kkc libkkc error
    gtk3
    xdg-utils
    vulkan-validation-layers
    zenity 
    xorg.libXrandr
    dbus
    libnsl
    # libunity # dee package error caused by this
    pciutils
    openal
    passt
    cups
    alsa-lib
    libxslt
    zstd
    xorg.libxshmfence
    avahi
    xorg.libpciaccess
    elfutils
    lm_sensors
    libffi
    flac
    libogg
    libbsd
    libxml2
    llvmPackages.libllvm
    libdrm.out
    unstable.libgbm
    unstable.libgbm.out
    libcap
    libcap_ng
    libcaption
    gmp
    gmpxx
    libgmpris
    SDL2
    SDL2_image
    SDL2_ttf
    bzip2
    sdlookup
    SDL2_net
    SDL2_gfx
    #  SDL_sound SDL2_sound # SLD_SOUND error
    SDL_sixel
    sdl-jstest
    SDL_compat
    
    # SDL_stretch SDL STREACH ERROR
    SDL_audiolib
    SDL2_image_2_6
    SDL2_image_2_0
    # SDL2_mixer SDL_mixer SDL2_mixer_2_0 # timidity error
    libcdada
    libgcc
    # xapp mate components? GIVES ERROR, ALSO, WHY would i need
    libselinux
    python3
    wayland
    wayland-protocols
    patchelf
    libGLU

    # Comments moved below:
    # libstdcxx5 ?
    # gcc-unwrapped.lib libgccjitga (gcc jit error)
    # libdbusmenu: causing Error: detected mismatched Qt dependencies when compiled for steamLibsI686 (maybe not)
    # sbclPackages.cl-cairo2-xlib sbcl error?
    # SDL sdl3 SDL2 sdlpop SDL_ttf SDL_net SDL_gpu SDL_gfx (-baseqt conflict error)
    # swiftshader (CPU implementation of vulkan)
    # libcef (https://github.com/ptitSeb/box64/issues/1383) error: unsupported system i686-linux
  ];

# still missing libs:
# cat tests.txt | grep "Error loading"                                                                                                                                             15:28:19
# Error loading needed lib libGLX.so
# Error loading needed lib libxapp-gtk3-module.so
# Error loading needed lib libvulkan.so.1
# Error loading needed lib libvulkan.so
# Error loading needed lib libunity.so.9
# Error loading needed lib libvulkan.so.1
# Error loading needed lib libvulkan.so


  # Get 32-bit counterparts using armv7l cross-compilation
  steamLibsAarch32 = let
    crossPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;
    getCrossLib = lib:
      let
        # Map problematic package names to their cross-compilation equivalents
        crossName = 
          if lib.pname or null == "gtk+" then "gtk2"
          else if lib.pname or null == "openal-soft" then "openalSoft"
          else if lib.pname or null == "systemd-minimal-libs" then "systemd"
          else if lib.pname or null == "ibus-engines.libpinyin" then "ibus-engines"
          else if lib ? pname then lib.pname
          else lib.name;
        
        # Handle special cases where attributes need different access
        finalPkg = crossPkgs.${crossName} or (throw "Missing cross package: ${crossName}");
      in
      builtins.tryEval finalPkg;
  in
    map (x: x.value) (filter (x: x.success) (map getCrossLib steamLibs));

  steamLibsX86_64 = let
    crossPkgs = pkgs.pkgsCross.gnu64;
    getCrossLib = lib:
      let
        # Map problematic package names to their cross-compilation equivalents
        crossName = 
          if lib.pname or null == "libdbusmenu" then "glibc"  # Skip libdbusmenu
          else if lib.pname or null == "qt5" then "glibc"     # Skip qt5 packages
          else if lib.pname or null == "gtk+-2.24.33" then "gtk2"
          else if lib.pname or null == "openal-soft" then "openalSoft"
          else if lib.pname or null == "systemd-minimal-libs" then "systemd"
          else if lib.pname or null == "ibus-engines.libpinyin" then "ibus-engines"
          else if lib ? pname then lib.pname
          else lib.name;
        
        # Handle special cases where attributes need different access
        finalPkg = crossPkgs.${crossName} or (throw "Missing cross package: ${crossName}");
      in
      builtins.tryEval finalPkg;
  in map (x: x.value) (filter (x: x.success) (map getCrossLib steamLibs));

  # steamLibsI686 = let
  #   crossPkgs = pkgs.pkgsCross.gnu32;
  #   getCrossLib = lib:
  #     let
  #       # Expand Qt-related blocklist
  #       qtBlocklist = [
  #         "pango" "xcbutilxrm" "libappindicator" "qtsvg" "qtbase"
  #         "qtdeclarative" "qtwayland" "qt5compat" "qtgraphicaleffects"
  #       ];
  #       # Map problematic package names to their cross-compilation equivalents
  #       crossName = 
  #         if lib.pname or null == "libdbusmenu" then "glibc"  # Skip libdbusmenu
  #         else if lib.pname or null == "swiftshader" then "glibc"     # Skip swiftshader packages 
  #         else if lib.pname or null == "libgccjit" then "glibc"     # Skip swiftshader packages 
  #         else if lib.pname or null == "qt5" then null     # Skip qt5 packages
  #         else if lib ? pname && lib.pname != "" && builtins.elem lib.pname qtBlocklist then "glibc"
  #         else if lib.pname or null == "xapp-gtk3" then "xapp-gtk3-module"
  #         else if lib.pname or null == "unity" then "libunity"
  #         else if lib.pname or null == "gtk+-2.24.33" then "gtk2"
  #         else if lib.pname or null == "openal-soft" then "openalSoft"
  #         else if lib.pname or null == "systemd-minimal-libs" then "systemd"
  #         else if lib.pname or null == "ibus-engines.libpinyin" then "ibus-engines"
  #         else if lib ? pname then lib.pname
  #         else if lib ? pname then lib.pname
  #         else lib.name;
        
  #       # Handle special cases where attributes need different access
  #       finalPkg = crossPkgs.${crossName} or (throw "Missing cross package: ${crossName}");
  #     in
  #     builtins.tryEval finalPkg;
  # in map (x: x.value) (filter (x: x.success) (map getCrossLib steamLibs));


  steamLibsMineX86_64 = let
    crossPkgs = pkgs.x86;
    getCrossLib = lib:
      let
        # Map problematic package names to their cross-compilation equivalents
        crossName = 
          if lib.pname or null == "xapp-gtk3" then "xapp-gtk3-module"
          else if lib.pname or null == "unity" then "libunity"
          else if lib.pname or null == "gtk+-2.24.33" then "gtk2"
          else if lib.pname or null == "openal-soft" then "openalSoft"
          else if lib.pname or null == "systemd-minimal-libs" then "systemd"
          else if lib.pname or null == "ibus-engines.libpinyin" then "ibus-engines"
          else if lib ? pname then lib.pname
          else lib.name;
        
        # Handle special cases where attributes need different access
        finalPkg = crossPkgs.${crossName} or (throw "Missing cross package: ${crossName}");
      in
      builtins.tryEval finalPkg;
  in map (x: x.value) (filter (x: x.success) (map getCrossLib steamLibs));

  steamLibsMinei686 = let
    crossPkgs = pkgs.i686;
    getCrossLib = lib:
      let
        # Map problematic package names to their cross-compilation equivalents
        crossName = 
          if lib.pname or null == "xapp-gtk3" then "xapp-gtk3-module"
          else if lib.pname or null == "unity" then "libunity"
          else if lib.pname or null == "gtk+-2.24.33" then "gtk2"
          else if lib.pname or null == "openal-soft" then "openalSoft"
          else if lib.pname or null == "systemd-minimal-libs" then "systemd"
          else if lib.pname or null == "ibus-engines.libpinyin" then "ibus-engines"
          else if lib ? pname then lib.pname
          else lib.name;
        
        # Handle special cases where attributes need different access
        finalPkg = crossPkgs.${crossName} or (throw "Missing cross package: ${crossName}");
      in
      builtins.tryEval finalPkg;
  in map (x: x.value) (filter (x: x.success) (map getCrossLib steamLibs));

in

/*
    export BOX64_LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") steamLibs}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu" # didn't help
    export LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") steamLibs}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu" # didn't help

    export BOX64_LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsAarch32)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu"
    export LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsAarch32)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu"

    export BOX64_LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsX86_64 ++ steamLibsI686)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu"
    export LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsX86_64 ++ steamLibsI686)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu"

    export BOX64_LD_LIBRARY_PATH="${ lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsMineX86_64)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu"
    export LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsMineX86_64)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu"
*/

let
  cfg = config.mySystem.box64;
  BOX64_LOG = "1";
  BOX64_DYNAREC_LOG = "0";
  STEAMOS = "1";
  STEAM_RUNTIME = "1";
  BOX64_VARS= ''
    export BOX64_DLSYM_ERROR=1;
    export BOX64_TRANSLATE_NOWAIT=1;
    export BOX64_NOBANNER=1;
    export STEAMOS=${STEAMOS}; # https://github.com/ptitSeb/box64/issues/91#issuecomment-898858125
    export BOX64_LOG=${BOX64_LOG};
    export BOX64_DYNAREC_LOG=${BOX64_DYNAREC_LOG};
    export DBUS_FATAL_WARNINGS=1;
    export STEAM_RUNTIME=${STEAM_RUNTIME};
    export SDL_VIDEODRIVER=x11;  # wayland
    export BOX64_TRACE_FILE="stderr"; # apparantly prevents steam sniper not found error https://github.com/Botspot/pi-apps/issues/2614#issuecomment-2209629910
    export BOX86_TRACE_FILE=stderr;

    # Set SwiftShader as primary
    export VULKAN_SDK="${pkgs.vulkan-headers}";
    export VK_LAYER_PATH="${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
    export VK_ICD_FILENAMES=${pkgs.swiftshader}/share/vulkan/icd.d/vk_swiftshader_icd.json; # vulkaninfo should work with CPU now, probably should remove if I MAKE THIS WORK

    export BOX64_LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsI686)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu";
    export LD_LIBRARY_PATH="${lib.concatMapStringsSep ":" (pkg: "${pkg}/lib") (steamLibs ++ steamLibsI686)}:$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/lib/i386-linux-gnu";

    export DBUS_FATAL_WARNINGS=0;
    BOX64_AVX=0;
    

  '';

  # FHS environment that spawns a bash shell by default, or runs a given command if arguments are provided
  steamFHS = pkgs.buildFHSUserEnv {
    name = "steam-fhs";
    targetPkgs = pkgs: (with pkgs; [
      mybox64 box86 steam-run xdg-utils
      vulkan-validation-layers vulkan-headers
      libva-utils swiftshader
    ]) ++ steamLibs;

  multiPkgs = pkgs: 
    steamLibs 
    #++ steamLibsAarch32 
    #++ steamLibsX86_64 
     ++ steamLibsI686 # getting the feeling that I only need these: https://github.com/ptitSeb/box64/issues/2142
    #++ steamLibsMineX86_64
    #++ steamLibsMinei686
    ;

    extraInstallCommands = ''
    '';

    runScript = ''
      # Enable box64/box86 logging if needed
      ${BOX64_VARS}

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

  exec ${steamFHS}/bin/steam-fhs ${pkgs.mybox64}/bin/mybox64 ${pkgs.x86.bash}/bin/bash "$@"
'';
box64Wrapper = pkgs.writeScriptBin "box64-wrapper" ''
  #!${pkgs.bash}/bin/sh

  ${BOX64_VARS}

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
      (self: super: let
        i686pkgs = import pkgs.path {
          system = "i686-linux";
          config.allowUnfree = true;
        };
      in {
        inherit (i686pkgs) ;
        #steam-run;
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
      #pkgs.x86.steamcmd
      heroicx86Wrapper
      steamx86Wrapper
      #pkgs.pkgsCross.gnu32.steam
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