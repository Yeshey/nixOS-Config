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
      # Tavily API key, read by the pi-tavily-search extension from
      # auth.json under the `tavily` entry. If the value already exists
      # under another sops key name, set `key = "<existing path>"` here
      # instead of adding a new entry to the sops file.
      sops.secrets."tavily_api_key" = { };

      sops.templates."pi-auth.json".content = builtins.toJSON {
        litellm = {
          type = "api_key";
          key = config.sops.placeholder."litellm_master_key";
        };
        tavily = {
          type = "api_key";
          key = config.sops.placeholder."tavily_api_key";
        };
      };

      home.file."${config.programs.pi-coding-agent.configDir}/auth.json".source =
        config.lib.file.mkOutOfStoreSymlink
          (toString config.sops.templates."pi-auth.json".path);

      programs.pi-coding-agent = 
        let
          ollamaBaseUrl = "http://hyrulecastle.tailb6874b.ts.net:11434/v1";
        in
      {
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
          # --- Wayland clipboard support ---
          wl-clipboard
        ];

        settings = {
          defaultProvider = "litellm";
          defaultModel = defaultModel;
          defaultThinkingLevel = "medium";
          theme = "dark";
          packages = [ "npm:@jmcombs/pi-tavily-search" ];

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

          providers.hyrule-ollama = {
            baseUrl = ollamaBaseUrl;
            api = "openai-completions";
            apiKey = "ollama"; # ollama ignores key, but field must be non-empty
            compat = {
              supportsDeveloperRole = false;
              supportsReasoningEffort = false;
            };
            models = [
              {
                id = "woof-fixed-64k";
                name = "Woof 4B (hyrulecastle)";
                reasoning = true; # model emits thinking
                contextWindow = 65536;
                maxTokens = 8192;
              }
            ];
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