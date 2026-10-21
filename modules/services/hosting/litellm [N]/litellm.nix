{
  flake.modules.nixos.litellm =
    { config, lib, ... }:
    let
      port = 4000;
    in
    {
      sops.secrets."gemini_api_key" = { };
      sops.secrets."litellm_master_key" = { };
      sops.secrets."nvidia_nim_api_key" = { };
      sops.secrets."vercel_key" = { };
      sops.secrets."cerebras_key" = { };
      sops.secrets."inceptio_mercury_api" = { };

      sops.templates."litellm.env" = {
        content = ''
          GEMINI_API_KEY=${config.sops.placeholder."gemini_api_key"}
          LITELLM_MASTER_KEY=${config.sops.placeholder."litellm_master_key"}
          NVIDIA_NIM_API_KEY=${config.sops.placeholder."nvidia_nim_api_key"}
          VERCEL_API_KEY=${config.sops.placeholder."vercel_key"}
          CEREBRAS_API_KEY=${config.sops.placeholder."cerebras_key"}
          INCEPTIO_MERCURY_API_KEY=${config.sops.placeholder."inceptio_mercury_api"}
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

      users.users.litellm = { isSystemUser = true; group = "litellm"; };
      users.groups.litellm = { };
      systemd.services.litellm.serviceConfig.User = "litellm";
      systemd.services.litellm.serviceConfig.Group = "litellm";

      services.litellm.environment = { };

      services.litellm = {
        enable = true;
        host = "0.0.0.0";
        port = port;
        openFirewall = true;

        settings = {
          model_list = [
            {
              model_name = "minicpm5-2b-hyrulecastle-ollama";
              litellm_params = {
                model = "ollama_chat/openbmb/minicpm5-2b:latest";
                api_base = "http://hyrulecastle.tailb6874b.ts.net:11434";
                extra_body = {
                  options = {
                    num_ctx = 32768;
                  };
                };
              };
            }
            # ---- Google AI Studio free tier ----
            {
              model_name = "gemini-3.8-flash";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
              };
            }
            {
              model_name = "gemini-3.6-flash";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
              };
            }
            {
              model_name = "gemini-3-flash";
              litellm_params = {
                model = "gemini/gemini-3-flash-preview";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
              };
            }
            {
              model_name = "gemini-3.1-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.1-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 14;
                tpm = 225000;
              };
            }
            {
              model_name = "gemini-3.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 14;
                tpm = 225000;
              };
            }
            {
              model_name = "gemini-3.5-flash";
              litellm_params = {
                model = "gemini/gemini-3.5-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
              };
            }
            {
              model_name = "gemini-3.7-flash";
              litellm_params = {
                model = "gemini/gemini-3.7-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
              };
            }
            {
              model_name = "gemma-4-26b";
              litellm_params = {
                model = "gemini/gemma-4-26b-a4b-it";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 29;
                tpm = 14400;
              };
            }
            {
              model_name = "gemma-4-31b";
              litellm_params = {
                model = "gemini/gemma-4-31b-it";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 29;
                tpm = 14400;
              };
            }

            # ---------------------------------------------------------------
            # Vercel AI Gateway + NVIDIA NIM + Cerebras deployments.
            # TB4.0 (artificialanalysis.ai, 2026-10-19):
            #   nvidia-glm-5-3 ...................... 0.419  (FREE NIM, deprecating ~11d)
            #   nvidia-glm-5-3-flash ................ 0.328  (FREE NIM)
            #   vercel-deepseek-v4-1-flash-1017-fast. 0.268  (Vercel $5/30d)
            #   gemini-3.8-flash .................... 0.197  (free AI Studio)
            #   gemini-3.7-flash .................... 0.136  (free AI Studio)
            #   cerebras-qwen-3-8-27b ............... 0.056  (Cerebras free tier)
            #   nvidia-muse-glimmer-30b ............. 0.005  (weak tail)
            #   nvidia-nemotron-3-5-lightning ....... 0.005  (weak tail)
            # ---------------------------------------------------------------

            {
              model_name = "vercel-muse-spark-1-3-contributor";
              litellm_params = {
                model = "openai/meta/muse-spark-1.3-contributor";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # 403 on free tier; strong-chain entry point falls through.
              };
            }
            {
              model_name = "nvidia-glm-5-3";
              litellm_params = {
                model = "openai/z-ai/glm-5.3";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
                # TB4.0: 0.419. FREE NIM endpoint. Deprecation notice ~11d.
              };
            }
            {
              model_name = "nvidia-glm-5-3-flash";
              litellm_params = {
                model = "openai/z-ai/glm-5.3-flash";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }
            {
              model_name = "vercel-deepseek-v4-1-flash-1017-fast";
              litellm_params = {
                model = "openai/deepseek/deepseek-v4.1-flash-1017-fast";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0.268. Vercel free $5/30d. 901 tps via Baseten.
              };
            }
            {
              model_name = "nvidia-muse-glimmer-30b";
              litellm_params = {
                model = "openai/meta/muse-glimmer-30b";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }
            {
              model_name = "nvidia-nemotron-3-5-lightning";
              litellm_params = {
                model = "openai/nvidia/nemotron-3.5-lightning-30b-a3b";
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
              model_name = "vercel-morph-v3-large";
              litellm_params = {
                model = "openai/morph/morph-v3-large";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }
            {
              model_name = "cerebras-qwen-3-8-27b";
              litellm_params = {
                model = "openai/qwen-3.8-27b";
                api_base = "https://api.cerebras.ai/v1";
                api_key = "os.environ/CEREBRAS_API_KEY";
                # TB4.0: 0.056 (Xhigh). Above muse-glimmer (0.005).
              };
            }

            # ---- Inception Labs Mercury ----
            # Defined only; intentionally NOT wired into any fallback chain.
            {
              model_name = "inceptio-mercury-3";
              litellm_params = {
                model = "openai/mercury-3";
                api_base = "https://api.inceptionlabs.ai/v1";
                api_key = "os.environ/INCEPTIO_MERCURY_API_KEY";
              };
            }

            # ---- Chain entry points ----
            {
              model_name = "strong-fallback-chain";
              litellm_params = {
                model = "openai/meta/muse-spark-1.3-contributor";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
              };
            }
            {
              model_name = "weak-fallback-chain";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
              };
            }
          ];

          router_settings = {
            optional_pre_call_checks = [ "enforce_model_rate_limits" ];
            fallbacks = [
              # ---- strong chain ----
              # Entry = muse-spark (via alias above). Then benchmark-ordered:
              #   GLM-5.3 (0.419) → GLM-5.3-Flash (0.328) → DeepSeek 1017-Fast (0.268)
              #   → Gemini 3.8 (0.197) → Gemini 3.7 (0.136)
              { strong-fallback-chain = [
                  "nvidia-glm-5-3"
                  "nvidia-glm-5-3-flash"
                  "vercel-deepseek-v4-1-flash-1017-fast"
                  "gemini-3.8-flash"
                  "gemini-3.7-flash"
                ]; }
              { nvidia-glm-5-3 = [
                  "nvidia-glm-5-3-flash"
                  "vercel-deepseek-v4-1-flash-1017-fast"
                  "gemini-3.8-flash"
                  "gemini-3.7-flash"
                ]; }
              { nvidia-glm-5-3-flash = [
                  "vercel-deepseek-v4-1-flash-1017-fast"
                  "gemini-3.8-flash"
                  "gemini-3.7-flash"
                ]; }
              { vercel-deepseek-v4-1-flash-1017-fast = [
                  "gemini-3.8-flash"
                  "gemini-3.7-flash"
                ]; }
              { "gemini-3.8-flash" = [ "gemini-3.7-flash" ]; }
              # gemini-3.7-flash = last

              # ---- weak chain ----
              # cerebras-qwen-3-8-27b (0.056) sits after the last Gemini/Gemma
              # hop but BEFORE the two 0.005 tail models.
              { weak-fallback-chain = [
                  "vercel-mimo-v2-5-pro" "vercel-kimi-k2-7-code"
                  "gemma-4-31b" "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5"
                  "gemini-3-flash" "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b"
                  "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { vercel-mimo-v2-5-pro = [
                  "vercel-kimi-k2-7-code" "gemma-4-31b" "gemini-3.5-flash" "gemma-4-26b"
                  "vercel-mimo-v2-5" "gemini-3-flash" "gemini-3.5-flash-lite"
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { vercel-kimi-k2-7-code = [
                  "gemma-4-31b" "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5"
                  "gemini-3-flash" "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b"
                  "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { gemma-4-31b = [
                  "gemini-3.5-flash" "gemma-4-26b" "vercel-mimo-v2-5" "gemini-3-flash"
                  "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite"
                  "cerebras-qwen-3-8-27b" "nvidia-muse-glimmer-30b"
                  "nvidia-nemotron-3-5-lightning"
                ]; }
              { "gemini-3.5-flash" = [
                  "gemma-4-26b" "vercel-mimo-v2-5" "gemini-3-flash" "gemini-3.5-flash-lite"
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { gemma-4-26b = [
                  "vercel-mimo-v2-5" "gemini-3-flash" "gemini-3.5-flash-lite"
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { vercel-mimo-v2-5 = [
                  "gemini-3-flash" "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b"
                  "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { gemini-3-flash = [
                  "gemini-3.5-flash-lite" "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite"
                  "cerebras-qwen-3-8-27b" "nvidia-muse-glimmer-30b"
                  "nvidia-nemotron-3-5-lightning"
                ]; }
              { "gemini-3.5-flash-lite" = [
                  "nvidia-gpt-oss-20b" "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { nvidia-gpt-oss-20b = [
                  "gemini-3.1-flash-lite" "cerebras-qwen-3-8-27b"
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { "gemini-3.1-flash-lite" = [
                  "cerebras-qwen-3-8-27b" "nvidia-muse-glimmer-30b"
                  "nvidia-nemotron-3-5-lightning"
                ]; }
              { cerebras-qwen-3-8-27b = [
                  "nvidia-muse-glimmer-30b" "nvidia-nemotron-3-5-lightning"
                ]; }
              { nvidia-muse-glimmer-30b = [ "nvidia-nemotron-3-5-lightning" ]; }
              # nvidia-nemotron-3-5-lightning = last
            ];
          };
        };
      };
    };
}