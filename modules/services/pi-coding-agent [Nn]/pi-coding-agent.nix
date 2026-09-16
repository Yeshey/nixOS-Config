# modules/services/pi-coding-agent [Nn]/pi-coding-agent.nix
{ inputs, ...}:
{
  flake.modules.homeManager.pi-coding-agent =
    { lib, config, pkgs, ... }:
    let
      # LiteLLM endpoint via Tailscale
      litellmHost = "skyloft.tailb6874b.ts.net";
      litellmPort = 4000;
      litellmBaseUrl = "http://${litellmHost}:${toString litellmPort}/v1";

      # The model name as registered in your local LiteLLM config
      litellmModelId = "weak-fallback-chain";
    in
    {
      imports = [
        (inputs.home-manager-unstable + "/modules/programs/pi-coding-agent.nix")
      ];

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
          defaultModel = litellmModelId;
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
          providers = {
            litellm = {
              baseUrl = litellmBaseUrl;
              api = "openai-completions";

              # Pi treats models as requiring auth even if the endpoint
              # doesn't. Use a dummy value if LiteLLM has no auth.
              apiKey = "sk-litellm";

              # LiteLLM may not understand the `developer` role or
              # `reasoning_effort` depending on the backend models.
              compat = {
                supportsDeveloperRole = false;
                supportsReasoningEffort = false;
              };

              models = [
                {
                  id = litellmModelId;
                  name = "Weak Fallback Chain (LiteLLM)";
                  reasoning = false;
                }
              ];
            };
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