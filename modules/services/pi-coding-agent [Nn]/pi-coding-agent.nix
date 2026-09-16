# modules/services/pi-coding-agent [Nn]/pi-coding-agent.nix
{ inputs, ... }:
{
  flake.modules.homeManager.pi-coding-agent =
    { lib, config, pkgs, ... }:
    let
      litellmHost = "skyloft.tailb6874b.ts.net";
      litellmPort = 4000;
      litellmBaseUrl = "http://${litellmHost}:${toString litellmPort}/v1";
      litellmModelId = "weak-fallback-chain";
    in
    {
      imports = [
        (inputs.home-manager-unstable + "/modules/programs/pi-coding-agent.nix")
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops.secrets."litellm_master_key" = { };

      # auth.json holds the real key. Rendered as a sops template so the
      # placeholder gets substituted with the decrypted secret.
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

        # Dummy apiKey satisfies the loader. Real key comes from auth.json
        # at request time (per the fix in pi issue #5953).
        models = {
          providers.litellm = {
            baseUrl = litellmBaseUrl;
            api = "openai-completions";
            apiKey = "from-auth-json";
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