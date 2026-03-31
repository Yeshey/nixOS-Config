{ ... }:
{
  flake.modules.nixos.openhands =
    { pkgs, ... }:
    let
      port = 3000;
      home = "/home/yeshey";
    in
    {
      # A good local LLM to use with this: https://ollama.com/skratos115/qwen2-7b-opendevin-f16

      # Use these commands to check if the container can access ollama:
      # sudo podman ps
      # sudo podman exec <CONTAINER ID> curl http://host.docker.internal:11434/api/generate -d '{"model":"huihui_ai/deepseek-r1-abliterated:8b","prompt":"hi"}'

      # https://docs.all-hands.dev/modules/usage/llms/local-llms

      virtualisation.podman.enable = true;

      virtualisation.oci-containers.containers.openhands = {
        image = "docker.all-hands.dev/all-hands-ai/openhands:0.29";
        autoStart = true;
        extraOptions = [
          "--rm"
          "--pull=always"
          "--add-host=host.docker.internal:host-gateway"
        ];
        ports = [ "${toString port}:${toString port}" ];
        environment = {
          SANDBOX_RUNTIME_CONTAINER_IMAGE = "docker.all-hands.dev/all-hands-ai/runtime:0.29-nikolaik";
          LOG_ALL_EVENTS = "true";
          LLM_OLLAMA_BASE_URL = "http://host.docker.internal:11434";
          LLM_BASE_URL = "http://host.docker.internal:11434";
        };
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "${home}/.openhands-state:/.openhands-state"
        ];
      };

      systemd.services.podman-openhands = {
        after = [ "network-online.target" "my-network-online.service" ];
        wants = [ "network-online.target" "my-network-online.service" ];
        requires = [ "network-online.target" "my-network-online.service" ];
      };

      systemd.services.openhands-mgr = {
        wantedBy = [ "multi-user.target" "podman-openhands.service" ];
        script = ''
          STATE_DIR="${home}/.openhands-state"
          echo "Ensuring OpenHands state directory exists..."
          if [ ! -d "$STATE_DIR" ]; then
            echo "Directory does not exist, creating..."
            mkdir -p "$STATE_DIR"
          else
            echo "Directory already exists."
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };

      environment.systemPackages =
        let
          openhandsWeb = pkgs.makeDesktopItem {
            name = "OpenHands";
            desktopName = "OpenHands";
            genericName = "OpenHands";
            exec = ''xdg-open "http://localhost:${toString port}"'';
            icon = "firefox";
            categories = [ "GTK" "X-WebApps" ];
            mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
          };
        in
        [ pkgs.xdg-utils openhandsWeb ];
    };
}