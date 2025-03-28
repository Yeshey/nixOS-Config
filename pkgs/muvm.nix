{
  pkgs,
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
let
  libkrun-muvm = pkgs.libkrun.overrideAttrs (old: {
    makeFlags = (old.makeFlags or [ ]) ++ [ "BLK=1" ];
  });
in
rustPlatform.buildRustPackage rec {
  pname = "muvm";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "AsahiLinux";
    repo = "muvm";
    rev = "muvm-${version}";
    hash = "sha256-K/Yhc/qYUhMlIOPF37O5n+60uSb1+vUJvYLH+WOjph0=";
  };

  cargoHash = "sha256-waaEnkJo47E/nvTphW1nGBjwZ8/iG3MtdbegPjp8VM4=";

  buildInputs = [
    libkrun-muvm
  ];

  nativeBuildInputs = [
    rustPlatform.bindgenHook
  ];

  meta = {
    description = "Muvm - run programs from your system in a microVM";
    homepage = "https://github.com/AsahiLinux/muvm";
    license = lib.licenses.unfree; # FIXME: nix-init did not find a license
    maintainers = with lib.maintainers; [ ];
    mainProgram = "muvm";
  };
}