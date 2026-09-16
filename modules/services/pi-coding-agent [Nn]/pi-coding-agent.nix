# modules/services/pi-coding-agent [Nn]/pi-coding-agent.nix
{ inputs, ... }:
{
  flake.modules.homeManager.pi-coding-agent =
    { lib, config, pkgs, ... }:
    let
      litellmHost = "skyloft.tailb6874b.ts.net";
      litellmPort = 4000;
      litellmBaseUrl = "http://${litellmHost}:${toString litellmPort}/v1";

      # LiteLLM models available to Pi. Add new entries here as your
      # LiteLLM config grows; the `id` must match the LiteLLM model name
      # exactly.
      litellmModels = [
        {
          id = "weak-fallback-chain";
          name = "Weak Fallback Chain (LiteLLM)";
          reasoning = false;
        }
        {
          id = "strong-fallback-chain";
          name = "Strong Fallback Chain (LiteLLM)";
          reasoning = false;
        }
      ];

      defaultModel = "weak-fallback-chain";
    in
    {
      imports = [
        (inputs.home-manager-unstable + "/modules/programs/pi-coding-agent.nix")
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops.secrets."litellm_master_key" = { };

      sops.templates."pi-auth.json".content = builtins.toJSON {
        litellm = {
          type = "api_key";
          key = config.sops.placeholder."litellm_master_key";
        };
      };

      home.file."${config.programs.pi-coding-agent.configDir}/auth.json".source =
        config.lib.file.mkOutOfStoreSymlink
          (toString config.sops.templates."pi-auth.json".path);

      programs.pi-coding-agent = {
        enable = true;
        package = pkgs.unstable.pi-coding-agent;

        extraPackages = with pkgs; [
          git
          curl
          jq
          ripgrep
          fd
          nodejs
          bun
        ];

        settings = {
          defaultProvider = "litellm";
          defaultModel = defaultModel;
          defaultThinkingLevel = "medium";
          theme = "dark";

          compaction = {
            enabled = true;
            reserveTokens = 16384;
            keepRecentTokens = 20000;
          };

          retry = {
            enabled = true;
            maxRetries = 3;
          };
        };

        models = {
          providers.litellm = {
            baseUrl = litellmBaseUrl;
            api = "openai-completions";
            apiKey = "from-auth-json";
            compat = {
              supportsDeveloperRole = false;
              supportsReasoningEffort = false;
            };
            models = litellmModels;
          };
        };

        context = ''
          # Pi Coding Agent — Global Context

          You are running on a NixOS host. Prefer `nix-shell` and Nix
          tooling over ad-hoc package installs. The host's `/nix` store
          is the source of truth for available binaries.

          When interacting with local services, prefer Tailscale
          hostnames (`*.tailb6874b.ts.net`) over `localhost`.
        '';
      };
    };
}