{ inputs, ... }:
{
  flake.modules.homeManager.desktop-items =
    { ... }:
    {
      imports = [
        inputs.self.modules.homeManager.desktop-items-xrdp
        inputs.self.modules.homeManager.desktop-items-openvscode-server
      ];
    };

  flake.modules.homeManager.desktop-items-xrdp =
    { pkgs, ... }:
    let
      ip = "143.47.53.175";
      user = "yeshey";
      extraclioptions = "/dynamic-resolution /p: /audio-mode:1 /clipboard /network:auto /compression /kbd:layout:0x0816 /gfx:AVC420 /cache:glyph:on,bitmap:on -wallpaper -menu-anims";
      gofreerdp = pkgs.writeShellScriptBin "gofreerdpserver" ''
        ${pkgs.freerdp}/bin/xfreerdp /v:${ip} /u:${user} ${extraclioptions}
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
    in
    {
      home.packages = [ pkgs.freerdp pkgs.xdg-utils gofreerdp freerdpDesktopItem ];
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
        icon = "vscode";
        categories = [ "GTK" "X-WebApps" ];
        mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
      };
    in
    {
      home.packages = [ pkgs.xdg-utils pkgs.openssh govscodeserver vscodeserverDesktopItem ];
    };
}