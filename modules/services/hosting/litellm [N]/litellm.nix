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

      services.litellm.environment = {
        MAX_RETRY_DELAY = "86400";     # 1 day
        INITIAL_RETRY_DELAY = "60";
        JITTER = "0.75";
      };

      services.litellm = {
        enable = true;
        host = "0.0.0.0";
        port = port;
        openFirewall = true;

        settings = {
          model_list = [
            # https://aistudio.google.com/rate-limit
            # track https://github.com/BerriAI/litellm/issues/14398
            # Google AI Studio free-tier quotas.
            # RPM uses max - 1 buffer.
            # TPM uses ~90% of listed max.

            {
              model_name = "gemini-3.8-flash";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-3.6-flash";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-2.5-flash";
              litellm_params = {
                model = "gemini/gemini-2.5-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-2.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-2.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 9;        # real limit 10
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-3-flash";
              litellm_params = {
                model = "gemini/gemini-3-flash-preview";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-3.1-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.1-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 14;       # real limit 15
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-3.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 14;       # real limit 15
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-3.5-flash";
              litellm_params = {
                model = "gemini/gemini-3.5-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemini-3.7-flash";
              litellm_params = {
                model = "gemini/gemini-3.7-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5
                tpm = 225000;   # real limit 250K
              };
            }

            {
              model_name = "gemma-4-26b";
              litellm_params = {
                model = "gemini/gemma-4-26b-a4b-it";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 29;       # real limit 30
                tpm = 14400;    # real limit 16K
              };
            }

            {
              model_name = "gemma-4-31b";
              litellm_params = {
                model = "gemini/gemma-4-31b-it";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 29;       # real limit 30
                tpm = 14400;    # real limit 16K
              };
            }
          ];

          router_settings = {
            optional_pre_call_checks = [ "enforce_model_rate_limits" ];
            num_retries = 100;
            allowed_fails = 100;
            cooldown_time = 86400;
            retry_policy = {
              RateLimitErrorRetries = 100;
              TimeoutErrorRetries = 100;
              InternalServerErrorRetries = 100;
              BadRequestErrorRetries = 100;
              AuthenticationErrorRetries = 100;
              ContentPolicyViolationErrorRetries = 100;
            };
          };
        };
      };
    };
}