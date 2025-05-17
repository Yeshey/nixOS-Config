# From this issue https://github.com/NixOS/nixpkgs/issues/308666
{ buildGoModule
, fetchFromGitHub
, lib
, pkg-config
, webkitgtk_4_1
, glib
, fuse
, installShellFiles
, wrapGAppsHook #(3)?
, glib-networking
, wrapperDir ? "/run/wrappers/bin"
}:
let
  pname = "onedriver";
  version = "0.14.2";

  src = fetchFromGitHub {
    owner = "yeshey";
    repo = "onedriver";
    rev = "v${version}";
    hash = "sha256-X0ZTbRIELo+LHWaAiKiq1jEQor9HlqpgKM0NDf06DBA=";
  };
in
buildGoModule {
  inherit pname version src;
  vendorHash = "sha256-JoinXXq9XuoXAa/ZgF3MIsKVooOUgKRS3KwWVWzjUJI=";

  nativeBuildInputs = [ pkg-config installShellFiles wrapGAppsHook ];
  buildInputs = [ webkitgtk_4_1 glib fuse glib-networking ];

  ldflags = [ "-X github.com/yeshey/onedriver/cmd/common.commit=63c205294b394ef135bc8ecb471b73e771968bbe" ];

  subPackages = [
    "cmd/onedriver"
    "cmd/onedriver-launcher"
  ];

  postInstall = ''
    echo "Running postInstall"
    install -Dm644 ./pkg/resources/onedriver.svg $out/share/icons/onedriver/onedriver.svg
    install -Dm644 ./pkg/resources/onedriver.png $out/share/icons/onedriver/onedriver.png
    install -Dm644 ./pkg/resources/onedriver-128.png $out/share/icons/onedriver/onedriver-128.png

    install -Dm644 ./pkg/resources/onedriver-launcher.desktop $out/share/applications/onedriver-launcher.desktop
    install -Dm644 ./pkg/resources/onedriver@.service $out/lib/systemd/user/onedriver@.service

    mkdir -p $out/share/man/man1
    installManPage ./pkg/resources/onedriver.1

    substituteInPlace $out/share/applications/onedriver-launcher.desktop \
      --replace "/usr/bin/onedriver-launcher" "$out/bin/onedriver-launcher" \
      --replace "/usr/share/icons" "$out/share/icons"

    substituteInPlace $out/lib/systemd/user/onedriver@.service \
      --replace "/usr/bin/onedriver" "$out/bin/onedriver" \
      --replace "/usr/bin/fusermount" "${wrapperDir}/fusermount"
  '';

  meta = with lib; {
    description = "Network filesystem for Linux";
    longDescription = ''
      onedriver is a network filesystem that gives your computer direct access to your files on Microsoft OneDrive.
      This is not a sync client. Instead of syncing files, onedriver performs an on-demand download of files when
      your computer attempts to use them. onedriver allows you to use files on OneDrive as if they were files on
      your local computer.
    '';
    inherit (src.meta) homepage;
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.massimogengarelli ];
    platforms = platforms.linux;
  };
}