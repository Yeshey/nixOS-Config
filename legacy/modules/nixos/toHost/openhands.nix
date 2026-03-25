{
  config,
  lib,
  pkgs,
  ... 
}:

let
  cfg = config.toHost.openhands;
  port = 3000;
  home = "/home/yeshey";
in
{
  options.toHost.openhands = {
    enable = lib.mkEnableOption "openhands";
    # You can add more options here if needed, e.g. for port, state directory, etc.
  };

  config = lib.mkIf cfg.enable {

    # Enable Podman/OCI container support.
    virtualisation.podman.enable = true;

    # a good local LLM to use with this: https://ollama.com/skratos115/qwen2-7b-opendevin-f16

    # Use These commands to check if the container can access and use ollama api:
    # sudo podman ps
    # sudo podman exec <CONTAINER ID> curl http://host.docker.internal:11434/api/generate -d '{"model":"huihui_ai/deepseek-r1-abliterated:8b","prompt":"hi"}'

    # https://docs.all-hands.dev/modules/usage/llms/local-llms
    # virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers = {
      openhands = {
        image = "docker.all-hands.dev/all-hands-ai/openhands:0.29";
        autoStart = true;
        extraOptions = [
          "--rm"
          "--pull=always"
          "--add-host=host.docker.internal:host-gateway" # finally working, backend is podman
          # "--add-host host.docker.internal:host-gateway"
        ];
        ports = [ "${toString port}:${toString port}" ];
        environment = {
          SANDBOX_RUNTIME_CONTAINER_IMAGE = "docker.all-hands.dev/all-hands-ai/runtime:0.29-nikolaik";
          LOG_ALL_EVENTS = "true";
          LLM_OLLAMA_BASE_URL="http://host.docker.internal:11434";
          LLM_BASE_URL="http://host.docker.internal:11434";
        };
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          # Assumes the home directory is set in config.home.homeDirectory.
          "${home}/.openhands-state:/.openhands-state"
        ];
      };
    };
    # WORKSPACE_DIR="./workspace"
    # LLM_API_KEY="ollama"
    # LLM_BASE_URL="http://localhost:11434"
    # LLM_EMBEDDING_MODEL="local"
    # LLM_MODEL ='ollama/llama2'

    systemd.services.podman-openhands = {
      # This adds to the settings that were already there
      after = [ "network-online.target" "my-network-online.service"];
      wants = [ "network-online.target" "my-network-online.service"];
      requires = [ "network-online.target" "my-network-online.service"];
    };

    # Service to ensure the OpenHands state directory exists
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

    # Add a desktop file to launch OpenHands in the browser.
    environment.systemPackages =
      with pkgs;
      let
        openhandsWeb = makeDesktopItem {
          name = "OpenHands";
          desktopName = "OpenHands";
          genericName = "OpenHands";
          exec = ''xdg-open "http://localhost:${toString port}"'';
          icon = "firefox";
          categories = [
            "GTK"
            "X-WebApps"
          ];
          mimeTypes = [
            "text/html"
            "text/xml"
            "application/xhtml_xml"
          ];
        };
      in
      [
        xdg-utils
        openhandsWeb
      ];

    # This should be to serve the model that seems to be the best one rn for openHands: https://www.all-hands.dev/blog/introducing-openhands-lm-32b----a-strong-open-coding-agent-model
    # You can use vllm to serve or maybe better sglang. Former has build errors, latter is not yet packaged, but seems like it might be soon.
    # systemd.services.vllm-openhands = {
    #   description = "vLLM server for all-hands/openhands-lm-32b-v0.1 model";
    #   wantedBy = [ "multi-user.target" ];
    #   wants = [ "my-network-online.service" ];
    #   after = [ "my-network-online.service" ];
    #   script = ''
    #     exec ${pkgs.python312Packages.vllm}/bin/python -m vllm.serve.serve --model=all-hands/openhands-lm-32b-v0.1 --port=11112
    #   '';
    #   serviceConfig = {
    #     Restart = "always";
    #     RestartSec = "5";
    #     User = "root";
    #     #WorkingDirectory = "${home}";
    #   };
    # };

  };
}
