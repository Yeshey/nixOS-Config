{ lib
, stdenv
, gccMultiStdenv
, fetchFromGitHub
, cmake
, python3
, pkgsCross
, gcc-arm-embedded
#, gcc-arm-embedded-13
}:

#pkgsCross.arm-embedded.
let
  crossPkgs = pkgsCross.armv7l-hf-multiplatform;
in
crossPkgs.stdenv.mkDerivation rec {
  pname = "box86";
  version = "0.3.6";

  src = fetchFromGitHub {
    owner = "ptitSeb";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Ywsf+q7tWcAbrwbE/KvM6AJFNMJvqHKWD6tuANxrUt8=";
  };

  buildInputs = [
    gcc-arm-embedded
  ];

  nativeBuildInputs = [
    cmake
    python3
    gcc-arm-embedded
  ];

  cmakeFlags = [
    "-DNOGIT=1"
    "-DARM_DYNAREC=ON"
  ];



/*
  cmakeFlags = [
    "-DNOGIT=1"
  ] ++ (
    if stdenv.hostPlatform.system == "armv7l-linux" then
      [
        "-DARM_DYNAREC=ON"
      ]
    else
      [
        "-DCMAKE_C_FLAGS=\"-m32\""
        "-DLD80BITS=1"
        "-DNOALIGN=1"
      ]
  ); */

  installPhase = ''
    runHook preInstall
    install -Dm 0755 box86 "$out/bin/box86"
    runHook postInstall
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ctest
    runHook postCheck
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/box86 -v
    runHook postInstallCheck
  '';

  meta = with lib; {
    homepage = "https://box86.org/";
    description = "Lets you run 32-bit Linux programs on arch 32-bit Linux systems";
    license = licenses.mit;
    maintainers = with maintainers; [ gador ];
    platforms = [ "armv7l-linux" ];
  };
}