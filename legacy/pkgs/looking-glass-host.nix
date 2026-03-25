# with help by https://www.kimi.com
{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  cmake,
  glib,
  # Core Host Dependencies
  nettle,
  libbfd, # For backtrace support

  # Capture Dependencies
  pipewire,
  libxcb, # For X11 capture support

  # Optional support flags
  backtraceSupport ? true,
  pipewireSupport ? true,
  xcbSupport ? true,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "looking-glass-host";
  version = "B7";

  src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = finalAttrs.version;
    hash = "sha256-I84oVLeS63mnR19vTalgvLvA5RzCPTXV+tSsw+ImDwQ=";
    fetchSubmodules = true;
  };

  # The host does not use nanosvg, so the patch is not needed.
  # patches = [ ... ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    nettle
    glib
    glib.dev
  ]
  ++ lib.optionals backtraceSupport [ libbfd ]
  ++ lib.optionals pipewireSupport [ pipewire ]
  ++ lib.optionals xcbSupport [ libxcb ];

  # These are host-specific cmake flags. The client ones are removed.
  # We assume the capture methods can be enabled/disabled via these flags
  # for a more robust derivation.
  cmakeFlags = [
    "-DOPTIMIZE_FOR_NATIVE=OFF"
    "-DWARNINGS_AS_ERRORS=OFF"
  ]
  ++ lib.optionals (!backtraceSupport) [ "-DENABLE_BACKTRACE=no" ]
  ++ lib.optionals (!pipewireSupport) [ "-DENABLE_PIPEWIRE=no" ] # Assuming this flag exists
  ++ lib.optionals (!xcbSupport) [ "-DENABLE_XCB=no" ]; # Assuming this flag exists

  env.NIX_CFLAGS_COMPILE = "-Wno-error=maybe-uninitialized"; # dont make warnings errors

  postUnpack = ''
    echo ${finalAttrs.src.rev} > source/VERSION
    # Set the correct source root for the host application
    export sourceRoot="source/host"
  '';

  # The host doesn't have an icon to install in the same way the client does.
  # postInstall = '' ... '';

  meta = with lib; {
    description = "Looking Glass KVMFR host application for the guest VM";
    longDescription = ''
      The Looking Glass Host application captures frames from the guest OS
      (in this case, Linux) using a capture API and sends them to the client
      through a low-latency transfer protocol over shared memory.

      WARNING: The upstream project considers the Linux host to be experimental
      and incomplete. Use at your own risk.
    '';
    homepage = "https://looking-glass.io/";
    license = licenses.gpl2Plus;
    mainProgram = "looking-glass-host";
    maintainers = with maintainers; [
      alexbakker
      babbaj
      j-brn
    ];
    platforms = [ "x86_64-linux" ];
  };
})