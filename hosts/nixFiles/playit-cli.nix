# Derivation, not a module!
{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "playit-agent";
  version = "1.0.0"; # for release 1.0.0-rc2;
  doCheck = false; # the tests weren't letting it build???
  # You have to change this to disable just the test that wasn't making it work: https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#running-package-tests-running-package-tests

  src = fetchFromGitHub {
    owner = "playit-cloud";
    repo = pname;
    rev = version;
    sha256 = "sha256-25j17LQn12Vm7Ybp0qKFN+nYQ9w3ys8RsM3ROy83V/w=";
  };

  cargoSha256 = "sha256-M5zO31AfuyX9zfyYiI2X3gFgEYhTQA95pmHSii+jNGY=";

  meta = with lib; {
    description = "game client to run servers without portforwarding";
    homepage = "https://playit.gg";
    license = licenses.unlicense;
    maintainers = [ "Yeshey" ];
  };
}