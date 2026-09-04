{ ... }:
{
  flake.modules.nixos.litellm =
    { config, ... }:
    let
      port = 4000; # keep this in sync with `litellmPort` in ollama.nix / openhands.nix
    in
    {
      sops.secrets."gemini_api_key" = { };
      sops.secrets."litellm_master_key" = { };

      sops.templates."litellm.env".content = ''
        GEMINI_API_KEY=${config.sops.placeholder."gemini_api_key"}
        LITELLM_MASTER_KEY=${config.sops.placeholder."litellm_master_key"}
      '';

      systemd.services.litellm.serviceConfig.EnvironmentFile = config.sops.templates."litellm.env".path;

      services.litellm = {
        enable = true;
        host = "0.0.0.0";
        port = port;
        openFirewall = true;

        settings.model_list = [
          {
            model_name = "gemini-3.6-flash";
            litellm_params = {
              model = "gemini/gemini-3.6-flash";
              api_key = "os.environ/GEMINI_API_KEY";
            };
          }
          {
            model_name = "gemini-3.8-flash";
            litellm_params = {
              model = "gemini/gemini-3.8-flash";
              api_key = "os.environ/GEMINI_API_KEY";
            };
          }
          {
            model_name = "gemini-3.5-flash-lite";
            litellm_params = {
              model = "gemini/gemini-3.5-flash-lite";
              api_key = "os.environ/GEMINI_API_KEY";
            };
          }
          {
            model_name = "gemini-3.1-pro-preview";
            litellm_params = {
              model = "gemini/gemini-3.1-pro-preview";
              api_key = "os.environ/GEMINI_API_KEY";
            };
          }
          {
            model_name = "gemini-2.5-pro";
            litellm_params = {
              model = "gemini/gemini-2.5-pro";
              api_key = "os.environ/GEMINI_API_KEY";
            };
          }
        ];
      };
    };
}