{ inputs, ... }:
{
  flake.modules.nixos.looped = { config, pkgs, ... }: {
    imports = [ inputs.looped.nixosModules.default ];

    sops.secrets = {
      looper_author_token = { };
      looper_reviewer_token = { };
      tavily_api_key = { };
      exa_api_key = { };
      forgejo_runner_token = { };
      # Already declared by your LiteLLM module; no second declaration needed.
      # litellm_master_key = { };
    };

    services.looped = {
      enable = true;
      repository = {
        provider = "forgejo";
        baseUrl = "https://skyloft.tailb6874b.ts.net:8443";
        owner = "Yeshey";
        name = "looped";
        defaultBranch = "main";
      };
      listenAddress = "skyloft.tailb6874b.ts.net";
      reviewer.requireReviewRequest = false;
      authMode = "none";
      secrets = {
        authorFile = config.sops.secrets.looper_author_token.path;
        reviewerFile = config.sops.secrets.looper_reviewer_token.path;
        litellmFile = config.sops.secrets.litellm_master_key.path;
      };
      toolSecretFiles = {
        TAVILY_API_KEY = config.sops.secrets.tavily_api_key.path;
        EXA_API_KEY = config.sops.secrets.exa_api_key.path;
      };
      litellm.baseUrl = "http://127.0.0.1:4000/v1";
      models = {
        #planner = "strong-fallback-chain";
        #reviewer = "strong-fallback-chain";
        planner = "weak-fallback-chain";
        reviewer = "weak-fallback-chain";
        worker = "weak-fallback-chain";
        fixer = "weak-fallback-chain";
      };
      # Example Python project. Replace these with your project's actual tests.
      extraPackages = [
        (pkgs.python3.withPackages (ps: [ ps.pytest ]))
        pkgs.nodejs
      ];
      validationCommands = [
        "git diff --check"
        "python -m pytest"
      ];
      cpuQuota = "100%";
      memoryMax = "infinity"; # Set from actual Skyloft capacity.
      autoMerge.enable = true;

      ci = {
        enable = true;
        runnerUuid = "40e74b63-c3eb-4b21-8a6e-224d4c1a8aac";
        runnerTokenFile = config.sops.secrets.forgejo_runner_token.path;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 17310 ];
  };
}