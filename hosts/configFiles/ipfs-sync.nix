# Derivation, not a module!
{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "ipfs-sync";
  version = "0.7.0";
  doCheck = false;

  src = fetchFromGitHub {
    owner = "TheDiscordian";
    repo = "ipfs-sync";
    rev = "v${version}";
    sha256 = "sha256-gXGu7UDhRNd6WYwh0dtQ5hUsThkczt+jKqHnGc2wdrE=";
  };

  vendorHash = "sha256-Snu6GmDcKrX+QqrbdH5NasGQqwJhScT1+u/zFI9M/9I=";

  nativeBuildInputs = [  ];

  CGO_ENABLED = 0;

  meta = with lib; {
    description = "ipfs-sync is a simple daemon which will watch files on your filesystem, mirror them to MFS, automatically update related pins, and update related IPNS keys, so you can always access your directories from the same address. You can use it to sync your documents, photos, videos, or even a website!";
    homepage = "https://github.com/TheDiscordian/ipfs-sync";
    license = licenses.bsd3;
    # maintainers = with maintainers; [ kalbasit ];
  };
}