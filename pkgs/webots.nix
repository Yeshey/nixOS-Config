{ lib, stdenv, fetchFromGitHub, cmake, swig, pkg-config, autoPatchelfHook, makeWrapper
, xorg, libGLU, glib, freeimage, freetype, libxml2, boost, libssh, libzip, readline
, openal, python3, qt5, xvfb-run, unzip, git, pbzip2, wget, zip, libxcrypt, libffi, zlib
, vulkan-loader, libXcursor, libXrandr, libXi, libX11, libXext, libXxf86vm, which, openjdk }:

let
  version = "R2025a";
in stdenv.mkDerivation {
  pname = "webots";
  inherit version;

  src = fetchFromGitHub {
    owner = "cyberbotics";
    repo = "webots";
    rev = version;
    hash = "sha256-QVXaBzF1IkkpN67TulE/0ITqYS5d7vts6eWnUiCqDDM=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    qt5.wrapQtAppsHook
    cmake
    swig
    pkg-config
    autoPatchelfHook
    makeWrapper
    git
    (python3.withPackages (ps: [ ps.pip ]))
    unzip
    pbzip2
    wget
    zip
    which
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtwebengine
    libGLU
    glib
    freeimage
    freetype
    libxml2
    boost
    libssh
    libzip
    readline
    openal
    xorg.libX11
    xorg.libXext
    xorg.libXxf86vm
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    vulkan-loader
    libxcrypt
    libffi
    zlib
    openjdk  # Added JDK for javac
  ];

  WEBOTS_HOME = builtins.getEnv "PWD";

  dontUseCmakeConfigure = true;

  preBuild = ''
    mkdir -p resources
    echo "main" > resources/branch.txt
    echo "cyberbotics/webots" > resources/repo.txt
    echo "0000000000000000000000000000000000000000" > resources/commit.txt

    # Fix Makefile include path
    substituteInPlace Makefile \
      --replace 'include $(WEBOTS_HOME_PATH)/resources/Makefile.os.include' \
                'include ./resources/Makefile.os.include'

    # Create fake lsb_release
    mkdir -p bin
    echo '#!/bin/sh' > bin/lsb_release
    echo 'echo "Distributor ID: Ubuntu"' >> bin/lsb_release
    echo 'echo "Release:        22.04"' >> bin/lsb_release
    chmod +x bin/lsb_release
    export PATH="$PWD/bin:$PATH"

    # Fix OpenAL path
    ln -sf ${openal}/lib/libopenal.so ${openal}/lib/libopenal.so.1

    # Set Java home
    export JAVA_HOME=${openjdk.home}
  '';

  buildPhase = ''
    runHook preBuild
    export LIBRARY_PATH=${lib.makeLibraryPath [ libGLU openal libffi zlib ]}
    export LD_LIBRARY_PATH=$LIBRARY_PATH
    
    # Disable dependency downloads
    export WEBOTS_DEPENDENCIES_PATH=$PWD/dependencies
    mkdir -p dependencies
    touch dependencies/webots-qt-6.5.3-linux64-release.tar.bz2
    
    make -j$NIX_BUILD_CORES release WEBOTS_HOME="$WEBOTS_HOME"
  '';

  installPhase = ''
    runHook preInstall

    # Install main binaries and resources
    mkdir -p $out
    cp -r . $out/webots

    # Create wrapper script with Qt environment
    mkdir -p $out/bin
    makeWrapper $out/webots/webots $out/bin/webots \
      --set QTWEBENGINE_DISABLE_SANDBOX 1 \
      --set WEBOTS_HOME $out/webots \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGLU openal vulkan-loader ]} \
      --prefix PATH : ${lib.makeBinPath [ xvfb-run ]} \
      "''${qtWrapperArgs[@]}"  # Add Qt wrapper arguments

    # Create desktop entry
    mkdir -p $out/share/applications
    cat > $out/share/applications/webots.desktop <<EOF
    [Desktop Entry]
    Name=Webots
    Exec=$out/bin/webots
    Icon=$out/webots/resources/icons/core/webots.png
    Type=Application
    Categories=Development;Simulation;
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open-source robot simulator";
    homepage = "https://cyberbotics.com";
    license = licenses.asl20;
    maintainers = [ "Yeshey" ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "webots";
  };
}