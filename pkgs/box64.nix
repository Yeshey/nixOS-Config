{
  lib,
  stdenv,
  fetchFromGitHub,
  gitUpdater,
  cmake,
  python3,
  withDynarec ? (
    stdenv.hostPlatform.isAarch64 || stdenv.hostPlatform.isRiscV64 || stdenv.hostPlatform.isLoongArch64
  ),
  runCommand,
  hello-x86_64,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mybox64";
  version = "0.3.4";
  binaryName = "mybox64";
  doCheck = false;

  src = fetchFromGitHub {
    owner = "ptitSeb";
    repo = "box64";
    rev = "v${finalAttrs.version}";
    hash = "sha256-CY5Emg5TsMVs++2EukhVzqn9440kF/BO8HZGQgCpGu4=";
  };

  nativeBuildInputs = [
    cmake
    python3
  ];

  cmakeFlags =
    [
      (lib.cmakeBool "NOGIT" true)

      # Arch mega-option
      (lib.cmakeBool "ARM64" stdenv.hostPlatform.isAarch64)
      (lib.cmakeBool "RV64" stdenv.hostPlatform.isRiscV64)
      (lib.cmakeBool "PPC64LE" (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian))
      (lib.cmakeBool "LARCH64" stdenv.hostPlatform.isLoongArch64)
    ]
    ++ lib.optionals stdenv.hostPlatform.isx86_64 [
      # x86_64 has no arch-specific mega-option, manually enable the options that apply to it
      (lib.cmakeBool "LD80BITS" true)
      (lib.cmakeBool "NOALIGN" true)
    ]
    ++ [
      # Arch dynarec
      (lib.cmakeBool "ARM_DYNAREC" (withDynarec && stdenv.hostPlatform.isAarch64))
      (lib.cmakeBool "RV64_DYNAREC" (withDynarec && stdenv.hostPlatform.isRiscV64))
      (lib.cmakeBool "LARCH64_DYNAREC" (withDynarec && stdenv.hostPlatform.isLoongArch64))
    ]
    ++ [
      # Box32 integration
      (lib.cmakeBool "BOX32" true)
      (lib.cmakeBool "BOX32_BINFMT" true)
    ];

  installPhase = ''
    runHook preInstall

    install -Dm 0755 box64 "$out/bin/${finalAttrs.binaryName}"

    runHook postInstall
  '';

  # doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  installCheckPhase = ''
    runHook preInstallCheck

    echo Checking if it works
    $out/bin/${finalAttrs.binaryName} -v 

    echo Checking if Dynarec option was respected
    $out/bin/${finalAttrs.binaryName} -v | grep ${lib.optionalString (!withDynarec) "-v"} Dynarec 

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
    tests.hello =
      runCommand "box64-test-hello" { nativeBuildInputs = [ finalAttrs.finalPackage ]; }
        # There is no actual "Hello, world!" with any of the logging enabled, and with all logging disabled it's hard to
        # tell what problems the emulator has run into.
        ''
          BOX64_NOBANNER=0 BOX64_LOG=1 ${finalAttrs.binaryName} ${lib.getExe hello-x86_64} --version | tee $out
        '';
  };

  meta = {
    homepage = "https://box86.org/";
    description = "Lets you run x86_64 Linux programs on non-x86_64 Linux systems";
    changelog = "https://github.com/ptitSeb/box64/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      gador
      OPNA2608
    ];
    mainProgram = finalAttrs.binaryName;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "riscv64-linux"
      "powerpc64le-linux"
      "loongarch64-linux"
      "mips64el-linux"
    ];
  };
})