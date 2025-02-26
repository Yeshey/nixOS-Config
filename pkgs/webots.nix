{ lib, stdenv, fetchurl, autoPatchelfHook, dpkg, makeWrapper, qt6
, xorg, alsa-lib, openssl, gtk3, libdrm, mesa, nss, nspr, libxkbcommon
, libappindicator-gtk3, libnotify, libuuid, at-spi2-core, cups, pango
, atk, cairo, gdk-pixbuf, glib, freetype, fontconfig, dbus, expat, udev
, libXdamage, libX11, libXcomposite, libXext, libXfixes, libXrandr
, libxshmfence, wayland, libGLU, zlib, libssh, libzip, zziplib, gd
, freeimage, sndio, ffmpeg, libxslt, libpulseaudio, openal }:

stdenv.mkDerivation rec {
  pname = "webots-bin";
  version = "R2025a";
  
  src = fetchurl {
    url = "https://github.com/cyberbotics/webots/releases/download/${version}/webots_2025a_amd64.deb";
    sha256 = "sha256-YlPVjJtiWoPte2LNhaZA/QVC1EHEjWM6YJMiCLQLBlc="; # Replace with actual hash
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
    xorg.libXrender
    xorg.libXi
    xorg.libXcursor
    xorg.libxcb
    alsa-lib
    openssl
    gtk3
    libdrm
    mesa
    nss
    nspr
    libxkbcommon
    libappindicator-gtk3
    libnotify
    libuuid
    at-spi2-core
    cups
    pango
    atk
    cairo
    gdk-pixbuf
    glib
    freetype
    fontconfig
    dbus
    expat
    udev
    libXdamage
    libXcomposite
    libXfixes
    libxshmfence
    wayland
    libGLU
    zlib
    libssh
    libzip
    zziplib
    gd
    freeimage
    sndio
    ffmpeg
    libxslt
    libpulseaudio
    openal
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    # Create directory structure
    mkdir -p $out/share/webots
    cp -r usr/local/* $out/share/webots
    
    # Create bin directory and symlink executable
    mkdir -p $out/bin
    ln -s $out/share/webots/bin/webots $out/bin/webots

    # Use qtWrapperArgs from wrapQtAppsHook
    wrapQtApp $out/bin/webots \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --set WEBOTS_HOME $out/share/webots
  '';

  meta = with lib; {
    description = "Mobile robot simulation software";
    homepage = "https://cyberbotics.com";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.yourName ];
  };
}