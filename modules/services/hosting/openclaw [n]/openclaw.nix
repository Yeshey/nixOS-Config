{ inputs, ... }:
{
  flake.modules.nixos.openclaw =
    { config, ... }:
    {
      users.users.yeshey.linger = true;

      sops.secrets.openclaw_gateway_password = {
        owner = "yeshey";
        mode = "0400";
      };
      sops.secrets.openclaw_moltbook_key = {
        key = "moltbook_api_key";
        owner = "yeshey";
        mode = "0400";
      };
      sops.secrets.telegram_openclawinator_bot = {
        owner = "yeshey";
        mode = "0400";
      };
      sops.templates."openclaw-litellm-key" = {
        owner = "yeshey";
        mode = "0400";
        content = config.sops.placeholder.litellm_master_key;
      };
      home-manager.users.yeshey.imports = [
        inputs.self.modules.homeManager.openclaw
      ];
    };

  flake.modules.homeManager.openclaw =
    { config, lib, pkgs, osConfig, ... }:
    let
      stateDir = "${config.home.homeDirectory}/.openclaw";
      workspace = name: "${stateDir}/workspaces/${name}";
      openclawPkgs = import inputs.nix-openclaw.inputs.nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        overlays = [ inputs.nix-openclaw.overlays.default ];
      };
      common = import ./_agents/common.nix { inherit pkgs; };
      roles = {
        orchestrator = import ./_agents/orchestrator.nix;
        planner = import ./_agents/planner.nix;
        worker = import ./_agents/worker.nix;
        reviewer = import ./_agents/reviewer.nix;
        fixer = import ./_agents/fixer.nix;
      };
      # Nested attributes merge; role lists replace common lists.
      agents = lib.mapAttrs (_: role:
        lib.recursiveUpdate common.defaults role
      ) roles;
      filesFor = name:
        agents.${name}.files // {
          "AGENTS.md" = common.sharedInstructions + "\n"
            + agents.${name}.instructions;
        };
      primaryFiles = filesFor "orchestrator";
      secretRef = provider: {
        source = "file";
        inherit provider;
        id = "value";
      };
    in
    {
      imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];
      systemd.user.startServices = "sd-switch";
      systemd.user.services.openclaw-gateway.Service = {
        StandardOutput = lib.mkForce "journal";
        StandardError = lib.mkForce "journal";
      };

      programs.openclaw = {
        enable = true;
        package = openclawPkgs.openclaw-gateway;
        toolNames = [ ];
        inherit stateDir;
        workspaceDir = workspace "orchestrator";
        runtimePackages = [ openclawPkgs.nodejs_24 ] ++ common.runtimePackages;
        skills = common.skillDefinitions;
        runtimePlugins = [ ];
        environment.MOLTBOOK_API_KEY =
          osConfig.sops.secrets.openclaw_moltbook_key.path;

        # Use upstream bootstrap management for the primary workspace.
        # toFile avoids evaluation-time ARM builds on the deploying x86 host.
        workspace.bootstrapFiles = {
          agents = builtins.toFile "AGENTS.md" primaryFiles."AGENTS.md";
          soul = builtins.toFile "SOUL.md" primaryFiles."SOUL.md";
          tools = builtins.toFile "TOOLS.md" primaryFiles."TOOLS.md";
          identity = builtins.toFile "IDENTITY.md" primaryFiles."IDENTITY.md";
          user = builtins.toFile "USER.md" primaryFiles."USER.md";
        };

        config = {
          channels.telegram = {
            enabled = true;
            tokenFile = osConfig.sops.secrets.telegram_openclawinator_bot.path;
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
              path = osConfig.sops.secrets.openclaw_gateway_password.path;
            };
            litellm-key = {
              source = "file";
              mode = "singleValue";
              path = osConfig.sops.templates."openclaw-litellm-key".path;
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
          plugins.entries."memory-core".config.dreaming.enabled = false;

          agents = {
            ownership = "explicit";
            defaults = {
              heartbeat.every = "0m";
              systemAgent.agentId = "orchestrator";
              model.primary = "litellm/${agents.orchestrator.model}";
              skipBootstrap = true;
              sandbox.mode = "off";
              subagents.requireAgentId = true;
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
            baseUrl = "http://127.0.0.1:4000/v1";
            apiKey = secretRef "litellm-key";
            api = "openai-completions";
            models = map (id: {
              inherit id;
              name = id;
              agentRuntime.id = "openclaw";
              reasoning = false;
              input = [ "text" ];
              inherit (common) contextWindow maxTokens;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }) (lib.unique (
              map (agent: agent.model) (builtins.attrValues agents)
            ));
          };
          tools = {
            profile = "full";
            alsoAllow = [ "message" ];

            exec = {
              host = "gateway";
              mode = "full";
            };

            fs.workspaceOnly = false;
          };
        };
      };

      # Home Manager manages the specialists' full bootstrap file sets.
      # Session history, MEMORY.md and memory/ remain runtime-owned.
      home.file = lib.listToAttrs (lib.concatLists (
        lib.mapAttrsToList (name: _: lib.mapAttrsToList (filename: text:
          lib.nameValuePair ".openclaw/workspaces/${name}/${filename}" {
            inherit text;
          }
        ) (filesFor name)) (builtins.removeAttrs agents [ "orchestrator" ])
      ));
    };
}