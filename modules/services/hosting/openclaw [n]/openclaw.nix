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

      # Use upstream's dependency set, avoiding the host's unsafe SQLite.
      openclawPkgs = import inputs.nix-openclaw.inputs.nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        overlays = [ inputs.nix-openclaw.overlays.default ];
      };

      agents = {
        orchestrator = {
          model = "weak-fallback-chain";
          instructions = ''
            Coordinate tasks and delegate to the declared specialists.
            Report progress and blockers accurately.
          '';
          skills = [ ];
          allowAgents = [ "planner" "worker" "reviewer" "fixer" ];
        };

        planner = {
          model = "weak-fallback-chain";
          instructions = ''
            Inspect the project and produce plans with concrete acceptance criteria.
            Implement changes only when asked.
          '';
          skills = [ ];
          allowAgents = [ ];
        };

        worker = {
          model = "weak-fallback-chain";
          instructions = ''
            Implement assigned tasks. Keep changes focused and run relevant tests.
          '';
          skills = [ ];
          allowAgents = [ ];
        };

        reviewer = {
          model = "weak-fallback-chain";
          instructions = ''
            Review changes for concrete defects supported by evidence.
            Distinguish cosmetic nits from blocking problems.
          '';
          skills = [ ];
          allowAgents = [ ];
        };

        fixer = {
          model = "weak-fallback-chain";
          instructions = ''
            Address supplied review findings and test failures.
            Preserve unrelated changes and validate your fixes.
          '';
          skills = [ ];
          allowAgents = [ ];
        };
      };

      workspace = name: "${stateDir}/workspaces/${name}";

      secretRef = provider: {
        source = "file";
        inherit provider;
        id = "value";
      };
    in
    {
      imports = [
        inputs.nix-openclaw.homeManagerModules.openclaw
      ];

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

        # Upstream manages the primary workspace bootstrap files.
        workspace.bootstrapFiles = {
          agents = builtins.toFile "AGENTS.md"
            agents.orchestrator.instructions;

          soul = builtins.toFile "SOUL.md" ''
            Be direct, accurate, and explicit about uncertainty.
          '';

          tools = builtins.toFile "TOOLS.md" ''
            Use available tools to complete assigned work.
            Report validation results accurately.
          '';

          identity = builtins.toFile "IDENTITY.md" ''
            You are the project orchestrator.
          '';

          user = builtins.toFile "USER.md" ''
            The user is Yeshey. Follow the user's instructions.
          '';
        };

        # Upstream materializes these skills and wires their load paths.
        # Example:
        # skills = [
        #   {
        #     name = "research";
        #     mode = "copy";
        #     source = "${./skills/research}";
        #   }
        # ];
        skills = [ ];

        runtimePackages = with pkgs; [
          git curl wget jq ripgrep findutils
          bashInteractive coreutils gnugrep gnused
          nix procps
          (python3.withPackages (ps: [ ps.pytest ]))
        ];

        config = {
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
          agents = {
            ownership = "explicit";
            defaults = {
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
              contextWindow = 128000;
              maxTokens = 16384;
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
            exec = {
              host = "gateway";
              mode = "full";
            };
            fs.workspaceOnly = false;
          };
        };
      };

      # Separate instructions for specialist workspaces.
      home.file = lib.mapAttrs' (name: agent:
        lib.nameValuePair ".openclaw/workspaces/${name}/AGENTS.md" {
          text = agent.instructions;
        }
      ) (builtins.removeAttrs agents [ "orchestrator" ]);
    };
}