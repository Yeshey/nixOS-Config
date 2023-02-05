# Derivation, not a module!
{ stdenv, fetchurl, pkgs, lib, ... }:

let
  version = "1.0.0-rc2";
  src = fetchurl {
    url = "https://github.com/playit-cloud/playit-agent/releases/download/v${version}/playit-cli";
    sha256 = "1rb4jlwbixv0r1pak83prvsa79mj4096jdzjiyngdp5p9khcims9";
  };

in stdenv.mkDerivation {
  name = "playit-cli-${version}";
  buildInputs = [ pkgs.cargo ];
  src = src;
  installPhase = ''
    tar xfz $src
    cd playit-agent-${version}
    cargo build --release --bin=playit-cli
    mkdir -p $out/bin
    cp target/release/playit-cli $out/bin
  '';
  meta = with stdenv.lib; {
    description = "Playit-cli agent ${version}";
    homepage = "https://github.com/playit-cloud/playit-agent";
    license = licenses.gpl3;
    platform = platforms.unix;
  };
}
