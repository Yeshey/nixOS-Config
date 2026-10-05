{ inputs, ... }:
{
  flake.modules.nixos.looped = { config, pkgs, ... }: {
    imports = [ inputs.looped.nixosModules.default ];

    sops.secrets = {
      looper_author_token = { };
      looper_reviewer_token = { };
      tavily_api_key = { };
      exa_api_key = { };
      # Already declared by your LiteLLM module; no second declaration needed.
      # litellm_master_key = { };
    };

    services.looped = {
      enable = true;
      repository = {
        provider = "forgejo";
        baseUrl = "http://127.0.0.1:3000";
        allowLoopbackHttp = true;
        owner = "Yeshey";
        name = "looped";
        defaultBranch = "main";
      };
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
        planner = "strong-fallback-chain";
        reviewer = "strong-fallback-chain";
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
      autoMerge.enable = false;
    };
  };
}