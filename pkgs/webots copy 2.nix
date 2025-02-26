{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, xorg, ffmpeg, openal, libGLU, qt5, xvfb-run, tree }:

stdenv.mkDerivation rec {
  pname = "webots";
  version = "R2025a";

  src = fetchurl {
    url = "https://github.com/cyberbotics/webots/releases/download/${version}/webots-${version}-x86-64.tar.bz2";
    sha256 = "sha256-xRJ/tCBsV6WuVSPxt/Pai2cLyJJtmuCFleE58ibzjDg="; # Replace with actual hash
  };

  nativeBuildInputs = [ 
    autoPatchelfHook 
    makeWrapper 
    qt5.wrapQtAppsHook
  ];
  buildInputs = [
    qt5.qtbase
    ffmpeg
    openal
    libGLU
    xorg.libXext
    xorg.xcbutilkeysyms
    xorg.xcbutilimage
    xorg.xcbutilwm
    xorg.xcbutilrenderutil
    xorg.libXinerama
    qt5.qtbase
    qt5.qtwebengine
    xvfb-run
  ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out
    cp -r webots $out/
    
    # Install wrapper script
    mkdir -p $out/bin
    ${tree}/bin/tree
    makeWrapper $out/webots/bin/webots-bin $out/bin/webots \
      --set QTWEBENGINE_DISABLE_SANDBOX 1 \
      --set WEBOTS_HOME $out/webots \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGLU openal ffmpeg ]} \
      --prefix PATH : ${lib.makeBinPath [ xvfb-run ]}

    # Symlink important directories
    ln -s $out/webots/resources $out/resources
    ln -s $out/webots/lib $out/lib
  '';

  # Ignore missing dependencies that can't be easily fixed
  autoPatchelfIgnoreMissingDeps = [
    "libsndio.so.7"
    "libImath-2_5.so.25"
    "libQt6WlShellIntegration.so.6"
  ];

  meta = with lib; {
    description = "Open-source robot simulator";
    homepage = "https://cyberbotics.com";
    maintainers = [ "Yeshey" ];
    platforms = [ "x86_64-linux" ];
  };
}