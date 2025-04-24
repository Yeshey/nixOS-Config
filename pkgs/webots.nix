{ lib
, stdenv
, fetchFromGitHub
, callPackage
, cmake
, swig
, libGL
, glib
, freeimage
, freetype
, libxml2
, boost
, libssh
, libzip
, readline
, pbzip2
, wget
, zip
, unzip
, python3
, openal
, openssl
, xvfb-run
, git
, bash
, makeWrapper
, qt5
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "webots";
  version = "2025a"; # Updated version format

  src = fetchFromGitHub {
    owner = "cyberbotics";
    repo = "webots";
    rev = "R${version}"; # Webots uses 'R' prefix for release tags
    fetchSubmodules = true;
    sha256 = "sha256-QVXaBzF1IkkpN67TulE/0ITqYS5d7vts6eWnUiCqDDM="; # Replace with actual hash after first attempt
  };

  nativeBuildInputs = [
    wrapQtAppsHook
    cmake
    swig
    python3
    git
    makeWrapper
  ];

  buildInputs = [
    libGL
    glib
    freeimage
    freetype
    libxml2
    boost
    libssh
    libzip
    readline
    pbzip2
    wget
    zip
    unzip
    python3
    openal
    openssl
    qt5.qtbase
    qt5.qtwayland
    qt5.qtwebsockets
  ];

  # Set environment variables needed by Webots
  WEBOTS_HOME = "${placeholder "out"}";
  WEBOTS_DISABLE_SAVE_SCREEN_PERSPECTIVE_ON_CLOSE = "1";
  WEBOTS_ALLOW_MODIFY_INSTALLATION = "1";

  # Fixing Qt installation path issues
  preConfigure = ''
    patchShebangs .
    substituteInPlace src/webots/Makefile \
      --replace '$(WEBOTS_HOME)/bin' '$(out)/bin'

    # We don't want to download Qt during the build
    # Since we're providing it through nixpkgs
    substituteInPlace dependencies/Makefile.linux \
      --replace './qt_linux_installer.sh' 'echo "Qt provided by nixpkgs"'

    # Make sure Webots finds the correct Qt location
    export QT_PLUGIN_PATH="${qt5.qtbase}/${qt5.qtbase.qtPluginPrefix}"
    export QT_QPA_PLATFORM_PLUGIN_PATH="${qt5.qtbase}/${qt5.qtbase.qtPluginPrefix}/platforms"
  '';

  buildPhase = ''
    make -j$NIX_BUILD_CORES release
  '';

  installPhase = ''
    mkdir -p $out
    cp -r bin lib include projects resources $out/

    # Create a wrapper script to set necessary environment variables
    makeWrapper $out/bin/webots $out/bin/webots-wrapped \
      --set WEBOTS_HOME $out \
      --set LD_LIBRARY_PATH "$out/lib:${lib.makeLibraryPath buildInputs}" \
      --set QT_PLUGIN_PATH "${qt5.qtbase}/${qt5.qtbase.qtPluginPrefix}" \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "${qt5.qtbase}/${qt5.qtbase.qtPluginPrefix}/platforms"

    # Replace original binary with wrapper
    mv $out/bin/webots-wrapped $out/bin/webots
    chmod +x $out/bin/webots
  '';

  meta = with lib; {
    description = "Open source robot simulator";
    homepage = "https://cyberbotics.com/";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [];
  };
}