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
      sops.secrets."groq_api_key" = { };
      sops.secrets."inceptio_mercury_api" = { };

      sops.templates."litellm.env" = {
        content = ''
          GEMINI_API_KEY=${config.sops.placeholder."gemini_api_key"}
          LITELLM_MASTER_KEY=${config.sops.placeholder."litellm_master_key"}
          NVIDIA_NIM_API_KEY=${config.sops.placeholder."nvidia_nim_api_key"}
          VERCEL_API_KEY=${config.sops.placeholder."vercel_key"}
          GROQ_API_KEY=${config.sops.placeholder."groq_api_key"}
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
              model_name = "mimo-v2.6-9b-hyrulecastle-ollama";
              litellm_params = {
                model = "ollama_chat/maternion/mimo-v2.6:9b";
                api_base = "http://hyrulecastle.tailb6874b.ts.net:11434";
                extra_body = {
                  options = {
                    num_ctx = 32768;
                  };
                };
              };
            }
            {
              model_name = "minicpm5-2b-ollama";
              litellm_params = {
                model = "ollama_chat/openbmb/minicpm5-2b";
                api_base = "http://hyrulecastle.tailb6874b.ts.net:11434";
                extra_body = {
                  options = {
                    num_ctx = 32768;
                  };
                };
              };
            }

            # ---- Google AI Studio free tier ----
            # Rate limits (peak/limit, 2026-10-24):
            #   gemini-3.8-flash     5 RPM, 250K TPM, 20 RPD
            #   gemini-3.7-flash     not in rate-limits table — verify
            #   gemini-3.6-flash     5 RPM, 250K TPM, 20 RPD
            #   gemini-3.5-flash     not in rate-limits table — verify
            #   gemini-3.5-flash-lite 15 RPM, 250K TPM, 500 RPD
            #   gemini-3.1-flash-lite 15 RPM, 250K TPM, 500 RPD
            #   gemini-3-flash       5 RPM, 250K TPM, 20 RPD (preview)
            #   gemma-4-26b          30 RPM, 16K TPM, 14.4K RPD
            #   gemma-4-31b          30 RPM, 16K TPM, 14.4K RPD
            # litellm_params.rpm/tpm below are set just under the provider
            # limits to avoid tripping them.
            {
              model_name = "gemini-3.8-flash";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
                # TB4.0: 0.197.
              };
            }
            {
              model_name = "gemini-3.7-flash";
              litellm_params = {
                model = "gemini/gemini-3.7-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
                # TB4.0: 0.1364.
              };
            }
            {
              model_name = "gemini-3.6-flash";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
                # TB4.0: 0.0707.
              };
            }
            {
              model_name = "gemini-3.5-flash";
              litellm_params = {
                model = "gemini/gemini-3.5-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
                # TB4.0: 0.0657.
              };
            }
            {
              model_name = "gemini-3.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 14;
                tpm = 225000;
                # TB4.0: 0.0101.
              };
            }
            {
              model_name = "gemini-3.1-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.1-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 14;
                tpm = 225000;
                # TB4.0: 0.0051. Weak-chain floor.
              };
            }
            {
              model_name = "gemini-3-flash";
              litellm_params = {
                model = "gemini/gemini-3-flash-preview";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
                # TB4.0: no AA match. Preview model — may be unstable.
              };
            }
            {
              model_name = "gemma-4-31b";
              litellm_params = {
                model = "gemini/gemma-4-31b-it";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 29;
                tpm = 14400;
                # TB4.0: no AA match. 31B dense — larger than 26b-a4b.
              };
            }
            {
              model_name = "gemma-4-26b";
              litellm_params = {
                model = "gemini/gemma-4-26b-a4b-it";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 29;
                tpm = 14400;
                # TB4.0: no AA match. MoE (26B total, 4B active).
              };
            }

            # ---------------------------------------------------------------
            # NVIDIA NIM free tier.
            # TB4.0 (artificialanalysis.ai, 2026-10-24):
            #   z-ai/glm-5.3 ......................... 0.4192  ⚠ DEPRECATION 10/27
            #   z-ai/glm-5.3-flash ................... 0.3283  ⚠ AVAILABLE=false
            #   deepseek-ai/deepseek-v4.1-flash ...... 0.2677  ✓ stable
            #   minimaxai/minimax-m3.1-flash ......... 0.2576
            #   meta/muse-glimmer-30b ................ 0.0051
            #   nvidia/nemotron-3.5-lightning-30b-a3b  0.0051
            # ---------------------------------------------------------------
            {
              model_name = "nvidia-glm-5-3";
              litellm_params = {
                model = "openai/z-ai/glm-5.3";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
                # TB4.0: 0.4192. ⚠ DEPRECATION 10/27/2026 — remove after.
              };
            }
            {
              model_name = "nvidia-glm-5-3-flash";
              litellm_params = {
                model = "openai/z-ai/glm-5.3-flash";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
                # TB4.0: 0.3283. ⚠ AVAILABLE=false on NGC.
              };
            }
            {
              model_name = "nvidia-deepseek-v4-1-flash";
              litellm_params = {
                model = "openai/deepseek-ai/deepseek-v4.1-flash";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
                # TB4.0: 0.2677. Stable NIM. Post-10/27 strong-chain head.
              };
            }
            {
              model_name = "nvidia-minimax-m3-1-flash";
              litellm_params = {
                model = "openai/minimaxai/minimax-m3.1-flash";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
                # TB4.0: 0.2576. Weak-chain provider diversification.
              };
            }
            {
              model_name = "nvidia-muse-glimmer-30b";
              litellm_params = {
                model = "openai/meta/muse-glimmer-30b";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
                # TB4.0: 0.0051. Opt-in tail.
              };
            }
            {
              model_name = "nvidia-nemotron-3-5-lightning";
              litellm_params = {
                model = "openai/nvidia/nemotron-3.5-lightning-30b-a3b";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
                # TB4.0: 0.0051. Opt-in tail.
              };
            }
            # ---------------------------------------------------------------
            # Vercel AI Gateway.
            # Rule: only ONE paid Vercel model may sit in any chain
            # (vercel-deepseek-v4-1-flash-1017). Everything else here is
            # opt-in or a $0/$0 tail.
            # ---------------------------------------------------------------
            {
              model_name = "vercel-deepseek-v4-1-flash-1017";
              litellm_params = {
                model = "openai/deepseek/deepseek-v4.1-flash-1017";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0.3384. Blend $0.12/1M. D=0.043. Single paid slot
                # across both chains. Non-fast sibling of -1017-fast at
                # 1/8th the price for identical TB.
              };
            }
            {
              model_name = "vercel-nemotron-3-5-lightning-free";
              litellm_params = {
                model = "openai/nvidia/nemotron-3.5-lightning-free";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0.0051 (inherited). $0/$0 pricing — valid free
                # tail for rule 1.
              };
            }
            {
              model_name = "vercel-deepseek-v4-1-flash-1017-fast";
              litellm_params = {
                model = "openai/deepseek/deepseek-v4.1-flash-1017-fast";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0.3384. Blend $0.96/1M. D=2.72. Opt-in only:
                # 8x price for identical TB. Latency-sensitive callers only.
              };
            }
            {
              model_name = "vercel-mimo-v2-5-pro";
              litellm_params = {
                model = "openai/xiaomi/mimo-v2.5-pro";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0. Opt-in only — superseded by mimo-v2.6-flash.
              };
            }
            {
              model_name = "vercel-kimi-k2-7-code";
              litellm_params = {
                model = "openai/moonshotai/kimi-k2.7-code";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0.0101. Blend $1.56/1M. D=240. Opt-in only.
              };
            }
            {
              model_name = "vercel-mimo-v2-5";
              litellm_params = {
                model = "openai/xiaomi/mimo-v2.5";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0. Opt-in only — superseded by mimo-v2.6-flash.
              };
            }
            {
              model_name = "vercel-morph-v3-large";
              litellm_params = {
                model = "openai/morph/morph-v3-large";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # No TB4.0 (edit-specialist, not chat). Opt-in only.
              };
            }
            {
              model_name = "vercel-muse-spark-1-3-contributor";
              litellm_params = {
                model = "openai/meta/muse-spark-1.3-contributor";
                api_base = "https://ai-gateway.vercel.sh/v1";
                api_key = "os.environ/VERCEL_API_KEY";
                # TB4.0: 0.3333* (inherited from Max — upper bound). Opt-in
                # only. Not in any chain: paid and no free fallback ensures
                # rule 1 is violated if used as an entry point.
              };
            }

            # ---- Groq free tier (no card; 30 RPM, 1k RPD, 200k TPD) ----
            # Defined but intentionally NOT in any chain. Preview model on
            # Groq; tool-use reliability is inconsistent. Opt-in only.
            {
              model_name = "groq-qwen-3-8-27b";
              litellm_params = {
                model = "openai/qwen/qwen3.8-27b";
                api_base = "https://api.groq.com/openai/v1";
                api_key = "os.environ/GROQ_API_KEY";
                # TB4.0: 0.0556. Fast LPU inference; independent provider.
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
                # No TB4.0. Opt-in only.
              };
            }

            # ---- Chain entry points ----
            # strong-fallback-chain routes to nvidia-glm-5-3's model today
            # (highest-TB free model). After 10/27/2026 GLM deprecates,
            # swap its model field to `openai/deepseek-ai/deepseek-v4.1-flash`
            # or let the chain's own fallback list take over at position #1.
            {
              model_name = "strong-fallback-chain";
              litellm_params = {
                model = "openai/z-ai/glm-5.3";
                api_base = "https://integrate.api.nvidia.com/v1";
                api_key = "os.environ/NVIDIA_NIM_API_KEY";
              };
            }
            {
              model_name = "weak-fallback-chain";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;
                tpm = 225000;
              };
            }
          ];

          router_settings = {
            optional_pre_call_checks = [ "enforce_model_rate_limits" ];
            fallbacks = [
              # =============================================================
              # strong chain (capability-first, free before paid, paid
              # before long tail of unscored free Geminis, $0/$0 tail last)
              # =============================================================
              # Fast path: top-4 free → paid. If paid succeeds, we get
              # TB 0.3384 at D 0.043 (cheap upgrade over gemini-3.7's 0.1364).
              # Slow path (paid fails / credit exhausted): fall through the
              # full free Gemini family, then $0/$0 tail.
              { strong-fallback-chain = [
                  "nvidia-glm-5-3-flash"                # free, 0.3283 ⚠ AVAILABLE=false
                  "nvidia-deepseek-v4-1-flash"          # free, 0.2677
                  "gemini-3.8-flash"                    # free, 0.197
                  "gemini-3.7-flash"                    # free, 0.1364
                  "vercel-deepseek-v4-1-flash-1017"     # paid, 0.3384, D 0.043
                  "gemini-3.6-flash"                    # free, 0.0707
                  "gemini-3.5-flash"                    # free, 0.0657
                  "gemini-3.5-flash-lite"               # free, 0.0101
                  "gemini-3.1-flash-lite"               # free, 0.0051
                  "gemini-3-flash"                      # free, no AA (preview)
                  "gemma-4-31b"                         # free, no AA (31B dense)
                  "gemma-4-26b"                         # free, no AA (MoE 26B/4B)
                  "vercel-nemotron-3-5-lightning-free"  # $0/$0, 0.0051 (tail)
                ]; }
              { nvidia-glm-5-3 = [
                  "nvidia-glm-5-3-flash"
                  "nvidia-deepseek-v4-1-flash"
                  "gemini-3.8-flash"
                  "gemini-3.7-flash"
                  "vercel-deepseek-v4-1-flash-1017"
                  "gemini-3.6-flash"
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { nvidia-glm-5-3-flash = [
                  "nvidia-deepseek-v4-1-flash"
                  "gemini-3.8-flash"
                  "gemini-3.7-flash"
                  "vercel-deepseek-v4-1-flash-1017"
                  "gemini-3.6-flash"
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { nvidia-deepseek-v4-1-flash = [
                  "gemini-3.8-flash"
                  "gemini-3.7-flash"
                  "vercel-deepseek-v4-1-flash-1017"
                  "gemini-3.6-flash"
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.8-flash" = [
                  "gemini-3.7-flash"
                  "vercel-deepseek-v4-1-flash-1017"
                  "gemini-3.6-flash"
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.7-flash" = [
                  "vercel-deepseek-v4-1-flash-1017"
                  "gemini-3.6-flash"
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { vercel-deepseek-v4-1-flash-1017 = [
                  "gemini-3.6-flash"
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.6-flash" = [
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.5-flash" = [
                  "gemini-3.5-flash-lite"
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.5-flash-lite" = [
                  "gemini-3.1-flash-lite"
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.1-flash-lite" = [
                  "gemini-3-flash"
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { gemini-3-flash = [
                  "gemma-4-31b"
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { gemma-4-31b = [
                  "gemma-4-26b"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { gemma-4-26b = [ "vercel-nemotron-3-5-lightning-free" ]; }
              # vercel-nemotron-3-5-lightning-free = last

              # =============================================================
              # weak chain (responsive-first, breadth over peak TB)
              # =============================================================
              # Entry: gemini-3.8-flash (via alias above).
              # Floor: gemini-3.1-flash-lite (TB 0.0051) — nothing weaker.
              { weak-fallback-chain = [
                  "gemini-3.7-flash"                    # free, 0.1364
                  "gemini-3.6-flash"                    # free, 0.0707
                  "gemini-3.5-flash"                    # free, 0.0657
                  "gemini-3.5-flash-lite"               # free, 0.0101
                  "nvidia-deepseek-v4-1-flash"          # free, 0.2677 (diversify)
                  "nvidia-minimax-m3-1-flash"           # free, 0.2576
                  "gemini-3.1-flash-lite"               # free, 0.0051 (floor)
                  "vercel-deepseek-v4-1-flash-1017"     # paid, 0.3384, D 0.043
                  "vercel-nemotron-3-5-lightning-free"  # $0/$0, 0.0051 (tail)
                ]; }
              { "gemini-3.7-flash" = [
                  "gemini-3.6-flash"
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "nvidia-deepseek-v4-1-flash"
                  "nvidia-minimax-m3-1-flash"
                  "gemini-3.1-flash-lite"
                  "vercel-deepseek-v4-1-flash-1017"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.6-flash" = [
                  "gemini-3.5-flash"
                  "gemini-3.5-flash-lite"
                  "nvidia-deepseek-v4-1-flash"
                  "nvidia-minimax-m3-1-flash"
                  "gemini-3.1-flash-lite"
                  "vercel-deepseek-v4-1-flash-1017"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.5-flash" = [
                  "gemini-3.5-flash-lite"
                  "nvidia-deepseek-v4-1-flash"
                  "nvidia-minimax-m3-1-flash"
                  "gemini-3.1-flash-lite"
                  "vercel-deepseek-v4-1-flash-1017"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.5-flash-lite" = [
                  "nvidia-deepseek-v4-1-flash"
                  "nvidia-minimax-m3-1-flash"
                  "gemini-3.1-flash-lite"
                  "vercel-deepseek-v4-1-flash-1017"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { nvidia-minimax-m3-1-flash = [
                  "gemini-3.1-flash-lite"
                  "vercel-deepseek-v4-1-flash-1017"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              { "gemini-3.1-flash-lite" = [
                  "vercel-deepseek-v4-1-flash-1017"
                  "vercel-nemotron-3-5-lightning-free"
                ]; }
              # vercel-nemotron-3-5-lightning-free = last
            ];
          };
        };
      };
    };
}