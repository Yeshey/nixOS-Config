# hlped by https://www.kimi.com
# to download the nvidia driver from google drive
{ pkgs }:
{ name, id, sha256 }:

pkgs.runCommandLocal name
{
  nativeBuildInputs = [ pkgs.python3Packages.gdown ];
  outputHashMode  = "flat";
  outputHashAlgo  = "sha256";
  outputHash      = sha256;

  # let gdown write its cookie file
  HOME = "/tmp";
}
''
  gdown "${id}" -O "$out"
''