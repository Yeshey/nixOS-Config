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
      systemd.tmpfiles.rules = [
        "Z /var/lib/litellm - - - -"
      ];

      services.litellm = {
        enable = true;
        host = "0.0.0.0";
        port = port;
        openFirewall = true;

        settings = {
          model_list = [
            # https://aistudio.google.com/rate-limit
            # track https://github.com/BerriAI/litellm/issues/14398
            {
              model_name = "gemini-3.6-flash";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5 — buffer of 1
                tpm = 225000;   # real limit 250K — ~10% buffer
              };
            }
            {
              model_name = "gemini-3.7-flash";
              litellm_params = {
                model = "gemini/gemini-3.7-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5 — buffer of 1
                tpm = 225000;   # real limit 250K — ~10% buffer
              };
            }
            {
              model_name = "gemini-3.8-flash";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5 — buffer of 1
                tpm = 225000;   # real limit 250K — ~10% buffer
              };
            }
            {
              model_name = "gemini-3.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 13;       # real limit 15
                tpm = 225000;   # real limit 250K
              };
            }
            {
              model_name = "gemini-3.5-flash";
              litellm_params = {
                model = "gemini/gemini-3.5-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 13;       # real limit 15
                tpm = 225000;   # real limit 250K
              };
            }
          ];

          router_settings = {
            optional_pre_call_checks = [ "enforce_model_rate_limits" ];
            allowed_fails = 1;        # 1 real 429 (e.g. RPD exhausted) trips cooldown
            cooldown_time = 86400;    # bench it 24h — covers daily-quota exhaustion
          };
        };
      };
    };
}