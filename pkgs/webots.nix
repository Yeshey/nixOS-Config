{ lib, stdenv, buildFHSUserEnv, fetchFromGitHub, autoPatchelfHook, python3, jdk, pkg-config, cmake
, qt6, ois, libGLU, libzip, zlib, openal, openssl, libssh2, curl, libxml2, gtk3, libusb1, libsndfile
, libpulseaudio, libogg, libvorbis, unixODBC, libuuid, libiodbc, libxcrypt, dbus, fontconfig, freetype
, xorg, libdrm, mesa, udev, nspr, nss, expat, alsa-lib, atk, cairo, cups, gdk-pixbuf, glib, gtk2
, at-spi2-atk, at-spi2-core, pango, harfbuzz, libjpeg, libpng, libtiff, wayland, libxkbcommon
, lsb-release, which, coreutils, git, python3Packages }:

let
  webotsBuild = stdenv.mkDerivation rec {
    pname = "webots";
    version = "R2025a";
    src = fetchFromGitHub {
      owner = "cyberbotics";
      repo = "webots";
      rev = version;
      sha256 = "sha256-QVXaBzF1IkkpN67TulE/0ITqYS5d7vts6eWnUiCqDDM=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      qt6.wrapQtAppsHook
      pkg-config
      cmake
      autoPatchelfHook
      python3
      python3Packages.virtualenv
      lsb-release
      which
      coreutils
      git
    ];

    buildInputs = [
      qt6.qtbase
      qt6.qtwayland
      libGLU
      libzip
      zlib
      jdk
      openal
      openssl
      libssh2
      curl
      libxml2
      gtk3
      libusb1
      libsndfile
      libpulseaudio
      libogg
      libvorbis
      unixODBC
      libuuid
      libiodbc
      libxcrypt
      dbus
      fontconfig
      freetype
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXinerama
      xorg.libXi
      xorg.libXext
      xorg.libXxf86vm
      xorg.libxcb
      xorg.libXrender
      xorg.libXtst
      xorg.libXau
      xorg.libXdmcp
      libdrm
      mesa
      udev
      nspr
      nss
      expat
      alsa-lib
      atk
      cairo
      cups
      gdk-pixbuf
      gtk2
      at-spi2-atk
      at-spi2-core
      pango
      harfbuzz
      libjpeg
      libpng
      libtiff
      wayland
      libxkbcommon
      ois
    ];

    prePatch = ''
      # Create fake lsb_release
      mkdir -p bin
      echo '#!/bin/sh' > bin/lsb_release
      echo 'echo "Distributor ID: NixOS"' >> bin/lsb_release
      chmod +x bin/lsb_release
      export PATH=$PWD/bin:$PATH

      # Fix OpenAL path
      ln -sf ${openal}/lib/libopenal.so lib/webots/libopenal.so
    '';

    buildPhase = ''
      # Create Python virtual environment
      #virtualenv venv
      #source venv/bin/activate

      # Build with FHS paths
      make -j$NIX_BUILD_CORES release
    '';

    installPhase = ''
      mkdir -p $out/share/webots
      cp -r . $out/share/webots

      # Create wrapper script
      mkdir -p $out/bin
      echo '#!/bin/sh' > $out/bin/webots
      echo "exec $out/share/webots/webots \"\$@\"" >> $out/bin/webots
      chmod +x $out/bin/webots
    '';

    dontConfigure = true;
    enableParallelBuilding = true;
  };

in buildFHSUserEnv {
  name = "webots";

  targetPkgs = pkgs: with pkgs; [
    # Base dependencies
    glibc
    zlib
    openssl
    libxml2
    curl
    libssh2
    openal
    unixODBC
    libuuid
    libxcrypt
    dbus
    fontconfig
    freetype
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    xorg.libxcb
    libdrm
    mesa
    alsa-lib
    cairo
    cups
    gdk-pixbuf
    gtk2
    pango
    harfbuzz
    libjpeg
    libpng
    libtiff
    wayland
    libxkbcommon
    ois

    # Qt dependencies
    qt6.qtbase
    qt6.qtwayland

    # Build tools
    python3
    python3Packages.virtualenv
    git
    cmake
    pkg-config
    jdk
  ];

  runScript = "${webotsBuild}/bin/webots";

  meta = with lib; {
    description = "Webots Robot Simulator (FHS environment)";
    homepage = "https://cyberbotics.com";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}