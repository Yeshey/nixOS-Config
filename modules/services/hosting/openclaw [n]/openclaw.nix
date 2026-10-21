# To approve:
# sudo nixos-container run openclaw -- su - openclaw -c 'openclaw devices approve <session-ID>'
# restart container:
# sudo systemctl restart container@openclaw

{ inputs, ... }:
{
  flake.modules.homeManager.openclaw =
    { config, lib, pkgs, ... }:
    let
      stateDir = "${config.home.homeDirectory}/.openclaw";
      workspace = name: "${stateDir}/workspaces/${name}";
      openclawPkgs = import inputs.nix-openclaw.inputs.nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        overlays = [ inputs.nix-openclaw.overlays.default ];
      };
      agents = {
        orchestrator = import ./_agents/orchestrator.nix;
        planner = import ./_agents/planner.nix;
        worker = import ./_agents/worker.nix;
        reviewer = import ./_agents/reviewer.nix;
        fixer = import ./_agents/fixer.nix;
        moltbooker = import ./_agents/moltbooker.nix;
      };

      # Every subdirectory containing a SKILL.md is a skill. Discovered, not listed.
      mkSkillDefinitions = dir:
        lib.mapAttrsToList
          (name: _: { inherit name; mode = "copy"; source = "${dir}/${name}"; })
          (lib.filterAttrs
            (name: type:
              type == "directory"
              && builtins.pathExists "${dir}/${name}/SKILL.md")
            (builtins.readDir dir));
      skillDefinitions =
        mkSkillDefinitions ./skills
        ++ mkSkillDefinitions ./_playground/skills;

      secretRef = provider: {
        source = "file";
        inherit provider;
        id = "value";
      };

      localCtx = {
        "mimo-v2.6-9b-hyrulecastle-ollama" = 32768;
      };

      mkLitellmModel = id: {
        inherit id;
        name = id;
        reasoning = false;
        input = [ "text" ];
        # Conservative: chains fall through GLM/DeepSeek/Gemini/etc. with
        # different limits, so cap at what the weakest hop can handle.
        # Local Ollama models override via `localCtx` above.
        contextWindow = localCtx.${id} or 128000;
        maxTokens = 8192;
      };

      litellmModelIds = lib.unique (
        [
          "strong-fallback-chain"
          "weak-fallback-chain"
          "inceptio-mercury-3"
          "mimo-v2.6-9b-hyrulecastle-ollama"
        ]
        ++ lib.mapAttrsToList (_: a: a.model) agents
      );
    in
    {
      imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];
      home.packages = with pkgs; [ gh git jq gh-token uv python3 file ];
      systemd.user.startServices = "sd-switch";
      systemd.user.services.openclaw-gateway.Service = {
        StandardOutput = lib.mkForce "journal";
        StandardError = lib.mkForce "journal";
      };
      # Ensure the gateway starts with the user manager at container boot,
      # not only when a session is opened.
      systemd.user.services.openclaw-gateway.Install.WantedBy =
        lib.mkForce [ "default.target" ];

      programs.openclaw = {
        enable = true;
        package = openclawPkgs.openclaw-gateway;
        toolNames = [ ];
        inherit stateDir;
        workspaceDir = workspace "orchestrator";
        skills = skillDefinitions;
        runtimePlugins = [ "tavily" ];
        environment.MOLTBOOK_API_KEY =
          "/run/openclaw-secrets/moltbook";
        environment.TAVILY_API_KEY =
          "/run/openclaw-secrets/tavily";

        config = {
          mcp.servers.nixos = {
            command = "uvx";
            args = [ "mcp-nixos" ];
          };
          channels.telegram = {
            enabled = true;
            tokenFile = "/run/openclaw-secrets/telegram";
            dmPolicy = "pairing";
          };
          bindings = [
            {
              agentId = "orchestrator";
              match = { channel = "telegram"; accountId = "*"; };
            }
          ];
          secrets.providers = {
            gateway-password = {
              source = "file";
              mode = "singleValue";
              path = "/run/openclaw-secrets/password";
            };
            litellm-key = {
              source = "file";
              mode = "singleValue";
              path = "/run/openclaw-secrets/litellm";
            };
          };
          gateway = {
            mode = "local";
            bind = "loopback";
            port = 18789;
            auth = {
              mode = "password";
              password = secretRef "gateway-password";
            };
            trustedProxies = [ "127.0.0.1" ];
            controlUi.allowedOrigins = [
              "https://skyloft.tailb6874b.ts.net:8444"
            ];
          };
          talk.agentId = "orchestrator";

          skills.workshop.autonomous.mode = "off";

          browser = {
            enabled = true;
            defaultProfile = "openclaw";
            headless = true;
            executablePath = "${pkgs.chromium}/bin/chromium";

            ssrfPolicy.allowedHostnames = [
              "skyloft.tailb6874b.ts.net"
            ];
          };

          plugins = {
            entries = {
              browser.enabled = true;
              litellm.enabled = true;
              "memory-core".config.dreaming.enabled = false;
            };
          };

          agents = {
            ownership = "explicit";
            defaults = {
              heartbeat.every = "0m";
              systemAgent.agentId = "orchestrator";
              model.primary = "litellm/${agents.orchestrator.model}";
              skipBootstrap = true;
              sandbox.mode = "off";
              subagents.requireAgentId = false;
              contextPruning = {
                mode = "cache-ttl";
                ttl = "1h"; # Adjust the TTL (default is 5 minutes)
              };
            };
            entries = lib.mapAttrs (name: agent: {
              inherit name;
              workspace = workspace name;
              agentDir = "${stateDir}/agents/${name}/agent";
              model = "litellm/${agent.model}";
              skills = agent.skills;
              subagents.allowAgents = agent.allowAgents;
              tools.allow = agent.tools;
            }) agents;
          };
          models.providers.litellm = {
            baseUrl = "http://127.0.0.1:4000";
            apiKey = secretRef "litellm-key";
            api = "openai-completions";
            models = map mkLitellmModel litellmModelIds;
          };
          tools = {
            profile = "full";
            alsoAllow = [ "message" ];

            web.search = {
              enabled = true;
              provider = "tavily";
            };

            exec = {
              host = "gateway";
              mode = "full";
            };

            fs.workspaceOnly = false;
          };
        };
      };

      # Regular files, not symlinks: OpenClaw rejects symlinked bootstrap files.
      # Runs after linkGeneration so HM's old-symlink cleanup can't delete the copies.
      home.activation.openclawWorkspaces = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.concatStrings (lib.concatLists (
          lib.mapAttrsToList (name: agent:
            lib.mapAttrsToList (filename: text:
              let
                src = builtins.toFile "${name}-${filename}" text;
                dest = "${workspace name}/${filename}";
              in ''
                run mkdir -p "${workspace name}"
                run rm -f "${dest}"
                run ${pkgs.coreutils}/bin/install -m 444 ${src} "${dest}"
              ''
            ) agent.files
          ) agents
        ))
      );
    };
}