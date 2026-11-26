
# modules/services/pi-coding-agent [Nn]/pi-coding-agent.nix
{ inputs, ... }:
{
  flake.modules.homeManager.pi-coding-agent =
    { lib, config, pkgs, ... }:
    let
      litellmHost = "skyloft.tailb6874b.ts.net";
      litellmPort = 4000;
      litellmBaseUrl = "http://${litellmHost}:${toString litellmPort}/v1";

      omnirouteHost = litellmHost;
      omniroutePort = 8445;
      omnirouteBaseUrl =
        "https://${omnirouteHost}:${toString omniroutePort}/v1";

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
        {
          id = "lfm3-hyrulecastle-ollama";
          name = "LFM3 (hyrulecastle)";
          reasoning = false;
        }
        {
          id = "hyrulecastle-qwen3-6-35b-a3b";
          name = "Qwen3 6/35B A3B (hyrulecastle)";
          reasoning = false;
        }
        {
          id = "onikao-qwen3-8-flash-next";
          name = "Qwen3 8 Flash Next (onikao)";
          reasoning = false;
        }
        {
          id = "ling3-tiny-hyrulecastle-ollama";
          name = "Ling 3 Tiny (hyrulecastle)";
          reasoning = false;
        }
      ];

      defaultModel = "weak-fallback-chain";

      piBase = pkgs.unstable.pi-coding-agent;

      piWrapped = pkgs.symlinkJoin {
        name = "pi-coding-agent-wrapped-${piBase.version}";
        paths = [ piBase ];
        inherit (piBase) meta;
        nativeBuildInputs = [ pkgs.makeWrapper ];

        postBuild = ''
          wrapProgram $out/bin/pi \
            --run 'export OMNIROUTE_API_KEY="$(cat ${config.sops.secrets."omniroute_api_key".path})"'
        '';
      };
    in
    {
      imports = [
        (inputs.home-manager-unstable + "/modules/programs/pi-coding-agent.nix")
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops.secrets."litellm_master_key" = { };
      sops.secrets."tavily_api_key" = { };
      sops.secrets."omniroute_api_key" = { };

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

      programs.pi-coding-agent = {
        enable = true;
        package = piWrapped;

        extraPackages = with pkgs; [
          git
          curl
          jq
          ripgrep
          fd
          nodejs
          bun
          wl-clipboard
        ];

        settings = {
          defaultProvider = "litellm";
          defaultModel = defaultModel;
          defaultThinkingLevel = "medium";
          theme = "dark";

          packages = [
            "npm:@jmcombs/pi-tavily-search"
            "npm:pi-models-discovery"
          ];

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
              apiKey = "from-auth-json";

              compat = {
                supportsDeveloperRole = false;
                supportsReasoningEffort = false;
              };

              models = litellmModels;
            };

            omniroute = {
              name = "OmniRoute";
              baseUrl = omnirouteBaseUrl;
              api = "openai-completions";
              apiKey = "$OMNIROUTE_API_KEY";
              discoverModels = true;
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
