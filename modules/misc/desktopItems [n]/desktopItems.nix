{ inputs, ... }:
{
  flake.modules.homeManager.desktop-items =
    { ... }:
    {
      imports = [
        inputs.self.modules.homeManager.desktop-items-xrdp
        inputs.self.modules.homeManager.desktop-items-openvscode-server
        inputs.self.modules.homeManager.desktop-items-ollama-webui
      ];
    };

  flake.modules.homeManager.desktop-items-xrdp =
    { pkgs, ... }:
    let
      # SSH config alias for skyloft. No public IP hardcoded.
      remote = "oracle";
      user = "yeshey";
      rdpPort = 3389;

      extraclioptions = "/dynamic-resolution /p: /audio-mode:1 /clipboard /network:auto /compression /kbd:layout:0x0816 /gfx:AVC420 /cache:glyph:on,bitmap:on -wallpaper -menu-anims";

      # SSH tunnel: local 3389 -> remote localhost:3389. Background ssh, wait
      # briefly for the forward to come up, launch xfreerdp against localhost,
      # then kill the tunnel when xfreerdp exits.
      gofreerdp = pkgs.writeShellScriptBin "gofreerdpserver" ''
        set -euo pipefail
        cleanup() { [ -n "''${SSH_PID:-}" ] && kill "$SSH_PID" 2>/dev/null || true; }
        trap cleanup EXIT
        ssh -N -L ${toString rdpPort}:localhost:${toString rdpPort} ${remote} &
        SSH_PID=$!
        # Poll until the local port accepts connections (max ~5s).
        for _ in $(seq 1 50); do
          if ${pkgs.iproute2}/bin/ss -tln "sport = :${toString rdpPort}" | grep -q LISTEN; then
            break
          fi
          sleep 0.1
        done
        ${pkgs.freerdp}/bin/xfreerdp /v:localhost:${toString rdpPort} /u:${user} ${extraclioptions}
      '';

      freerdpDesktopItem = pkgs.makeDesktopItem {
        name = "FreeRDP Oracle";
        desktopName = "FreeRDP Oracle";
        genericName = "FreeRDP Oracle";
        exec = "${gofreerdp}/bin/gofreerdpserver";
        icon = (pkgs.fetchurl {
          url = "https://github.com/FreeRDP/FreeRDP/raw/master/client/iOS/Resources/Icon.png";
          sha256 = "0arbqzzzcmd5m0ysdpydr2mm734vmldjjjbydf1p8njld4kz2klm";
        });
        categories = [ "GTK" "X-WebApps" ];
        mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
        terminal = true;
      };

      # Onikao entry unchanged — already reaches skyloft over Tailscale IP,
      # which is fine. If you want to kill the Tailscale dependency here too,
      # swap to an SSH tunnel the same way using your ssh alias.
      onikaoIp = "onikao";
      onikaoUser = "yeshey";
      onikaoExtraCliOptions = "/dynamic-resolution /audio-mode:1 /clipboard /network:auto /compression /kbd:layout:0x0816 /gfx:AVC420 /cache:glyph:on,bitmap:on -wallpaper -menu-anims";
      gofreerdpOnikao = pkgs.writeShellScriptBin "gofreerdponikao" ''
        ${pkgs.freerdp}/bin/xfreerdp /v:${onikaoIp}:3389 /u:${onikaoUser} ${onikaoExtraCliOptions}
      '';
      freerdpOnikaoDesktopItem = pkgs.makeDesktopItem {
        name = "FreeRDP Onikao";
        desktopName = "FreeRDP Onikao";
        genericName = "FreeRDP Onikao";
        exec = "${gofreerdpOnikao}/bin/gofreerdponikao";
        icon = (pkgs.fetchurl {
          url = "https://github.com/FreeRDP/FreeRDP/raw/master/client/iOS/Resources/Icon.png";
          sha256 = "0arbqzzzcmd5m0ysdpydr2mm734vmldjjjbydf1p8njld4kz2klm";
        });
        categories = [ "GTK" "X-WebApps" ];
        mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
        terminal = true;
      };
    in
    {
      home.packages = [
        pkgs.freerdp
        pkgs.openssh
        pkgs.iproute2
        pkgs.xdg-utils
        gofreerdp
        freerdpDesktopItem
        gofreerdpOnikao
        freerdpOnikaoDesktopItem
      ];
    };

  flake.modules.homeManager.desktop-items-openvscode-server =
    { pkgs, ... }:
    let
      remote = "oracle";
      port = 2998;
      govscodeserver = pkgs.writeShellScriptBin "govscodeserver" ''
        (ssh -L ${toString port}:localhost:${toString port} -t ${remote} "sleep 90" &) && sleep 1.5 && xdg-open "http://localhost:${toString port}/?folder=/home/yeshey/.setup"
      '';
      vscodeserverDesktopItem = pkgs.makeDesktopItem {
        name = "Oracle vscode-server";
        desktopName = "Oracle vscode-server";
        genericName = "Oracle vscode-server";
        exec = "${govscodeserver}/bin/govscodeserver";
        icon = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/VSCodium/vscodium/master/icons/stable/codium_cnl.svg";
          sha256 = "sha256-mBcDa9L1rdZy5wfaMRowEDOtEi1sLFBcd2y0jTW5RHI=";
        };
        categories = [ "GTK" "X-WebApps" ];
        mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
      };
    in
    {
      home.packages = [ pkgs.xdg-utils pkgs.openssh govscodeserver vscodeserverDesktopItem ];
    };

  flake.modules.homeManager.desktop-items-ollama-webui =
    { pkgs, ... }:
    let
      remote = "hyrulecastle";
      port = 11111;
      goollamawebui = pkgs.writeShellScriptBin "goollamawebui" ''
        (ssh -L ${toString port}:localhost:${toString port} -t ${remote} "sleep 90" &) && sleep 1.5 && xdg-open "http://localhost:${toString port}/?web-search=true"
      '';
      ollamawebuiDesktopItem = pkgs.makeDesktopItem {
        name = "Hyrulecastle Ollama WebUI";
        desktopName = "Hyrulecastle Ollama WebUI";
        genericName = "Hyrulecastle Ollama WebUI";
        exec = "${goollamawebui}/bin/goollamawebui";
        icon = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/open-webui/open-webui/main/static/favicon.png";
          sha256 = "sha256-Vpij45UT57YwTslsMJNzqzrw9w/nlCk0Yd45WpTeqmU=";
        };
        categories = [ "GTK" "X-WebApps" ];
        mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
      };
    in
    {
      home.packages = [ pkgs.xdg-utils pkgs.openssh goollamawebui ollamawebuiDesktopItem ];
    };
}