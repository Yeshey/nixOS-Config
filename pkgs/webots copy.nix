{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, wrapGAppsHook
, qt6
, xorg
, alsa-lib
, openssl
, gtk3
, libdrm
, mesa
, nss
, nspr
, libxkbcommon
, libappindicator-gtk3
, libnotify
, libuuid
, at-spi2-core
, cups
, pango
, atk
, cairo
, gdk-pixbuf
, glib
, freetype
, fontconfig
, dbus
, expat
, udev
, libXdamage
, libXcomposite
, libXext
, libXfixes
, libXrandr
, libxshmfence
, wayland
, libGLU
, zlib
, libssh
, libzip
, zziplib
, gd
, freeimage
, sndio
, ffmpeg
, libxslt
, libpulseaudio
, openal
, bzip2
}:

stdenv.mkDerivation rec {
  pname = "webots";
  version = "R2025a";
  
  src = fetchurl {
    url = "https://github.com/cyberbotics/webots/releases/download/${version}/webots-${version}-x86-64.tar.bz2";
    hash = "sha256-xRJ/tCBsV6WuVSPxt/Pai2cLyJJtmuCFleE58ibzjDg="; # Replace with the actual hash of the file
  };

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook
    bzip2
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

  dontConfigure = true;
  dontBuild = true;

  # Simple unpack - the tar.bz2 already has a webots directory structure
  unpackPhase = ''
    mkdir -p webots
    tar xf $src -C .
  '';

  installPhase = ''
    # Create directory structure
    mkdir -p $out
    cp -r webots/* $out/
    
    # Ensure the executable is actually executable
    chmod +x $out/bin/webots
    
    # Create a wrapper script with required environment variables
    wrapProgram $out/bin/webots \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --set WEBOTS_HOME $out
  '';

  meta = with lib; {
    description = "Mobile robot simulation software";
    homepage = "https://cyberbotics.com";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ "Yeshey" ]; # Add your maintainer name here
  };
}