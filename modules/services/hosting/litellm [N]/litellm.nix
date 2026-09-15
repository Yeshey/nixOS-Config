{ ... }:
{
  flake.modules.nixos.litellm =
    { config, lib, ... }:
    let
      port = 4000; # keep this in sync with `litellmPort` in ollama.nix / openhands.nix
    in
    {
      sops.secrets."gemini_api_key" = { };
      sops.secrets."litellm_master_key" = { };
      sops.secrets."nvidia_nim_api_key" = { };
      sops.secrets."vercel_key" = { };

      sops.templates."litellm.env" = {
        content = ''
          GEMINI_API_KEY=${config.sops.placeholder."gemini_api_key"}
          LITELLM_MASTER_KEY=${config.sops.placeholder."litellm_master_key"}
          NVIDIA_NIM_API_KEY=${config.sops.placeholder."nvidia_nim_api_key"}
          VERCEL_API_KEY=${config.sops.placeholder."vercel_key"}
        '';
        restartUnits = [ "litellm.service" ];
      };

      systemd.services.litellm = {
        serviceConfig.EnvironmentFile = config.sops.templates."litellm.env".path;
        serviceConfig.DynamicUser = lib.mkForce false;
        unitConfig.RequiresMountsFor = config.sops.templates."litellm.env".path;
        serviceConfig.Restart = "on-failure";
        serviceConfig.RestartSec = "5s";
        startLimitIntervalSec = 120;
        startLimitBurst = 10;
      };

      # FIX 2: Run litellm as a static, unprivileged user instead of root.
      users.users.litellm = {
        isSystemUser = true;
        group = "litellm";
      };
      users.groups.litellm = { };
      systemd.services.litellm.serviceConfig.User = "litellm";
      systemd.services.litellm.serviceConfig.Group = "litellm";

      services.litellm.environment = {
        # MAX_RETRY_DELAY = "86400";     # 1 day
        # INITIAL_RETRY_DELAY = "60";
        # JITTER = "0.75";
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

            # ---------------------------------------------------------------
            # Fallback-chain-only deployments (vercel AI Gateway + NVIDIA NIM).
            # model = "openai/<id>" against each provider's OpenAI-compatible
            # endpoint. All slugs verified against each provider's /v1/models
            # on 2026-09-07.
            # ---------------------------------------------------------------

            {
              model_name = "vercel-muse-spark-1-3";
              litellm_params = {
                model = "openai/meta/muse-spark-1.3";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "vercel-muse-spark-1-3-contributor";
              litellm_params = {
                model = "openai/meta/muse-spark-1.3-contributor";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "nvidia-kimi-k3";
              litellm_params = {
                model = "openai/moonshotai/kimi-k3";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }

            {
              model_name = "vercel-glm-5-3-flash";
              litellm_params = {
                model = "openai/zai/glm-5.3-flash";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "vercel-glm-5-2";
              litellm_params = {
                model = "openai/zai/glm-5.2";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "nvidia-minimax-m3";
              litellm_params = {
                model = "openai/minimaxai/minimax-m3";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }

            {
              model_name = "vercel-mimo-v2-5-pro";
              litellm_params = {
                model = "openai/xiaomi/mimo-v2.5-pro";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "vercel-kimi-k2-7-code";
              litellm_params = {
                model = "openai/moonshotai/kimi-k2.7-code";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "vercel-mimo-v2-5";
              litellm_params = {
                model = "openai/xiaomi/mimo-v2.5";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "nvidia-gpt-oss-20b";
              litellm_params = {
                model = "openai/openai/gpt-oss-20b";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }

            {
              model_name = "nvidia-nemotron-4-340b";
              litellm_params = {
                model = "openai/nvidia/nemotron-4-340b-instruct";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }

            {
              model_name = "vercel-mimo-v2-5-pro-ultraspeed";
              litellm_params = {
                model = "openai/xiaomi/mimo-v2.5-pro-ultraspeed";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "vercel-morph-v3-large";
              litellm_params = {
                model = "openai/morph/morph-v3-large";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            # ---------------------------------------------------------------
            # Chain entry-point aliases. Each alias points at its chain's
            # first deployment; router_settings.fallbacks carries it through
            # the rest. Overlapping deployments are shared across chains
            # (no extra API load, litellm dedupes by litellm_params).
            # ---------------------------------------------------------------

            {
              model_name = "auto-fallback-chain";       # full 24-deep chain
              litellm_params = {
                model = "openai/meta/muse-spark-1.3";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "strong-fallback-chain";     # top-7 strong models only
              litellm_params = {
                model = "openai/meta/muse-spark-1.3";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }

            {
              model_name = "weak-fallback-chain";       # solid-but-cheap tier, 14 deep
              litellm_params = {
                model = "openai/minimaxai/minimax-m3";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }
          ];

          router_settings = {
            optional_pre_call_checks = [ "enforce_model_rate_limits" ];
            # num_retries = 100;
            # allowed_fails = 100;
            # cooldown_time = 86400;
            # retry_policy = {
            #   RateLimitErrorRetries = 100;
            #   TimeoutErrorRetries = 100;
            #   InternalServerErrorRetries = 100;
            #   BadRequestErrorRetries = 100;
            #   AuthenticationErrorRetries = 100;
            #   ContentPolicyViolationErrorRetries = 100;
            # };
            fallbacks = [
              {
                auto-fallback-chain = [
                  "vercel-muse-spark-1-3-contributor" "gemini-3.8-flash" "nvidia-kimi-k3"
                  "gemini-3.7-flash" "vercel-glm-5-3-flash" "vercel-glm-5-2" "nvidia-minimax-m3"
                  "gemini-3.6-flash" "vercel-mimo-v2-5-pro" "vercel-kimi-k2-7-code" "gemma-4-31b"
                  "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5" "gemini-3-flash"
                  "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite"
                  "gemini-2.5-flash" "gemini-2.5-flash-lite" "nvidia-nemotron-4-340b"
                  "vercel-mimo-v2-5-pro-ultraspeed" "vercel-morph-v3-large"
                ]; # broken, leave as-is per your call
              }

              # ---- strong-fallback-chain ----
              { strong-fallback-chain = [
                  "vercel-muse-spark-1-3-contributor" "gemini-3.8-flash" "nvidia-kimi-k3"
                  "gemini-3.7-flash" "vercel-glm-5-3-flash" "vercel-glm-5-2"
                ]; }
              { vercel-muse-spark-1-3-contributor = [
                  "gemini-3.8-flash" "nvidia-kimi-k3" "gemini-3.7-flash"
                  "vercel-glm-5-3-flash" "vercel-glm-5-2"
                ]; }
              { "gemini-3.8-flash" = [
                  "nvidia-kimi-k3" "gemini-3.7-flash" "vercel-glm-5-3-flash" "vercel-glm-5-2"
                ]; }
              { nvidia-kimi-k3 = [
                  "gemini-3.7-flash" "vercel-glm-5-3-flash" "vercel-glm-5-2"
                ]; }
              { "gemini-3.7-flash" = [ "vercel-glm-5-3-flash" "vercel-glm-5-2" ]; }
              { vercel-glm-5-3-flash = [ "vercel-glm-5-2" ]; }
              # vercel-glm-5-2 = last

              # ---- weak-fallback-chain ----
              { weak-fallback-chain = [
                  "gemini-3.6-flash" "vercel-mimo-v2-5-pro" "vercel-kimi-k2-7-code"
                  "gemma-4-31b" "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5"
                  "gemini-3-flash" "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b"
                  "gemini-3.1-flash-lite" "gemini-2.5-flash" "gemini-2.5-flash-lite"
                ]; }
              { "gemini-3.6-flash" = [
                  "vercel-mimo-v2-5-pro" "vercel-kimi-k2-7-code" "gemma-4-31b"
                  "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5" "gemini-3-flash"
                  "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite"
                  "gemini-2.5-flash" "gemini-2.5-flash-lite"
                ]; }
              { vercel-mimo-v2-5-pro = [
                  "vercel-kimi-k2-7-code" "gemma-4-31b" "gemini-3.5-flash" "gemma-4-26b"
                  "vercel-mimo-v2-5" "gemini-3-flash" "gemini-3.5-flash-lite"
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "gemini-2.5-flash"
                  "gemini-2.5-flash-lite"
                ]; }
              { vercel-kimi-k2-7-code = [
                  "gemma-4-31b" "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5"
                  "gemini-3-flash" "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b"
                  "gemini-3.1-flash-lite" "gemini-2.5-flash" "gemini-2.5-flash-lite"
                ]; }
              { gemma-4-31b = [
                  "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5" "gemini-3-flash"
                  "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite"
                  "gemini-2.5-flash" "gemini-2.5-flash-lite"
                ]; }
              { "gemini-3.5-flash" = [
                  "gemma-4-26b" "vercel-mimo-v2-5" "gemini-3-flash" "gemini-3.5-flash-lite"
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "gemini-2.5-flash"
                  "gemini-2.5-flash-lite"
                ]; }
              { gemma-4-26b = [
                  "vercel-mimo-v2-5" "gemini-3-flash" "gemini-3.5-flash-lite"
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "gemini-2.5-flash"
                  "gemini-2.5-flash-lite"
                ]; }
              { vercel-mimo-v2-5 = [
                  "gemini-3-flash" "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b"
                  "gemini-3.1-flash-lite" "gemini-2.5-flash" "gemini-2.5-flash-lite"
                ]; }
              { gemini-3-flash = [
                  "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite"
                  "gemini-2.5-flash" "gemini-2.5-flash-lite"
                ]; }
              { "gemini-3.5-flash-lite" = [
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "gemini-2.5-flash"
                  "gemini-2.5-flash-lite"
                ]; }
              { nvidia-gpt-oss-20b = [
                  "gemini-3.1-flash-lite" "gemini-2.5-flash" "gemini-2.5-flash-lite"
                ]; }
              { "gemini-3.1-flash-lite" = [ "gemini-2.5-flash" "gemini-2.5-flash-lite" ]; }
              { "gemini-2.5-flash" = [ "gemini-2.5-flash-lite" ]; }
              # gemini-2.5-flash-lite = last
            ];
          };
        };
      };
    };
}

# vercelAPI/.Muse Spark 1.3
# vercelAPI/.Muse Spark 1.3 Contributor
# googleAPI/.gemini-3.8-flash
# nvidiaAPI/.moonshotai/kimi-k3
# googleAPI/.gemini-3.7-flash
# vercelAPI/.GLM 5.3 Flash
# vercelAPI/.GLM 5.2
# nvidiaAPI/.minimaxai/minimax-m3
# googleAPI/.gemini-3.6-flash
# vercelAPI/.MiMo V2.5 Pro
# vercelAPI/.Kimi K2.7 Code
# googleAPI/.gemma-4-31b
# googleAPI/.gemini-3.5-flash
# googleAPI/.gemma-4-26b
# vercelAPI/.MiMo M2.5
# googleAPI/.gemini-3-flash
# googleAPI/.gemini-3.5-flash-lite
# nvidiaAPI/.openai/gpt-oss-20b
# googleAPI/.gemini-3.1-flash-lite
# googleAPI/.gemini-2.5-flash
# googleAPI/.gemini-2.5-flash-lite
# nvidiaAPI/.nvidia/nemotron-4-340b-instruct
# vercelAPI/.MiMo V2.5 Pro UltraSpeed
# vercelAPI/.Morph V3 Large