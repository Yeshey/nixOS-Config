{ inputs, ... }:
{
  flake.modules.nixos.browser-agent =
    { pkgs, config, lib, ... }:
    let
      display = ":99";
      cdpPort = 9222;
      vncPort = 5900;
      novncPort = 6080;
      mcpoPort = 8765;
    in
    {
      environment.systemPackages = [
        pkgs.chromium
        pkgs.xvfb          # was pkgs.xorg.xvfb
        pkgs.x11vnc
        pkgs.novnc
        pkgs.nodejs
      ];

      # ── Virtual display ──────────────────────────────────────────────
      systemd.services.xvfb-display = {
        description = "Xvfb virtual display for browser agent";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.xvfb}/bin/Xvfb ${display} -screen 0 1280x800x24";  # was pkgs.xorg.xvfb
          Restart = "always";
        };
      };

      # ── Chromium with CDP exposed ────────────────────────────────────
      systemd.services.chromium-agent = {
        description = "Chromium with remote debugging for agent";
        after = [ "xvfb-display.service" ];
        wants = [ "xvfb-display.service" ];
        wantedBy = [ "multi-user.target" ];
        environment.DISPLAY = display;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.chromium}/bin/chromium \
              --remote-debugging-port=${toString cdpPort} \
              --remote-debugging-address=0.0.0.0 \
              --no-sandbox --no-first-run \
              --user-data-dir=/var/lib/chromium-agent
          '';
          StateDirectory = "chromium-agent";
          Restart = "always";
        };
      };

      # ── VNC + noVNC (human fallback viewer) ──────────────────────────
      systemd.services.x11vnc = {
        description = "x11vnc server for browser agent";
        after = [ "xvfb-display.service" ];
        wants = [ "xvfb-display.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display ${display} -forever -shared -nopw -rfbport ${toString vncPort}";
          Restart = "always";
        };
      };

      systemd.services.novnc = {
        description = "noVNC web viewer for browser agent";
        after = [ "x11vnc.service" ];
        wants = [ "x11vnc.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.novnc}/bin/novnc \
              --vnc localhost:${toString vncPort} \
              --listen ${toString novncPort} \
              --web ${pkgs.novnc}/share/webapps/novnc
          '';
          Restart = "always";
        };
      };

      # ── Playwright MCP proxied through mcpo ──────────────────────────
      systemd.services.playwright-mcp = {
        description = "Playwright MCP server proxied via mcpo";
        after = [ "chromium-agent.service" ];
        wants = [ "chromium-agent.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.nodejs ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.nodejs}/bin/npx -y mcpo --port ${toString mcpoPort} -- \
              npx -y @playwright/mcp@latest --cdp-endpoint http://localhost:${toString cdpPort}
          '';
          Restart = "always";
        };
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [
        novncPort
        mcpoPort
      ];
    };
}