{ lib, stdenv, fetchFromGitHub, cmake, swig, pkg-config, autoPatchelfHook, makeWrapper
, xorg, libGLU, glib, freeimage, freetype, libxml2, boost, libssh, libzip, readline
, openal, python3, qt5, xvfb-run, unzip, git, pbzip2, wget, zip, libxcrypt
, vulkan-loader, libXcursor, libXrandr, libXi, libX11, libXext, libXxf86vm }:

let
  version = "R2025a";
in stdenv.mkDerivation {
  pname = "webots";
  inherit version;

  src = fetchFromGitHub {
    owner = "cyberbotics";
    repo = "webots";
    rev = version;
    hash = "sha256-QVXaBzF1IkkpN67TulE/0ITqYS5d7vts6eWnUiCqDDM="; # Replace with actual hash
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
    python3
    unzip
    pbzip2
    wget
    zip
  ];

  buildInputs = [
    qt5.qtbase
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
    qt5.qtbase
    qt5.qtwebengine
    xorg.libX11
    xorg.libXext
    xorg.libXxf86vm
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    vulkan-loader
    libxcrypt
  ];

  WEBOTS_HOME = "$(pwd)";

  dontUseCmakeConfigure = true;

  preBuild = ''
    # Patch git-related scripts to work in Nix build environment
    substituteInPlace scripts/get_git_info/get_git_info.sh \
      --replace "git branch" "echo \"* main\"" \
      --replace "git config --get remote.origin.url" "echo https://github.com/cyberbotics/webots"

    echo "main" > resources/branch.txt
    echo "cyberbotics/webots" > resources/repo.txt
    echo "0000000000000000000000000000000000000000" > resources/commit.txt

    # Set up fake home directory for build
    export HOME=$(mktemp -d)
  '';

  buildPhase = ''
    runHook preBuild
    
    # Build with multiple cores
    make -j$NIX_BUILD_CORES release WEBOTS_HOME="$WEBOTS_HOME"
  '';

  installPhase = ''
    runHook preInstall

    # Install main binaries and resources
    mkdir -p $out
    cp -r . $out/webots

    # Create wrapper script
    mkdir -p $out/bin
    makeWrapper $out/webots/webots $out/bin/webots \
      --set QTWEBENGINE_DISABLE_SANDBOX 1 \
      --set WEBOTS_HOME $out/webots \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGLU openal vulkan-loader ]} \
      --prefix PATH : ${lib.makeBinPath [ xvfb-run ]}

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