{ pkgs }:
{
  defaults = {
    model = "weak-fallback-chain";
    skills = [ ];
    allowAgents = [ ];
    tools = [
      "ls" "read" "write" "edit" "apply_patch" "exec" "process"
      "web_search" "tavily_search" "tavily_extract"
    ];
    instructions = "";
    files = {
      "SOUL.md" = ''
        Be direct and accurate. Distinguish observed facts from assumptions.
        Report failures honestly and ask for clarification when requirements conflict.
      '';
      "IDENTITY.md" = "You are a specialist in Yeshey's project team.";
      "TOOLS.md" = ''
        Shell commands run on Skyloft as yeshey without an agent sandbox.
        Use git worktrees when working concurrently on the same repository.
        Report the commands run and their results. Do not claim unperformed tests passed.
      '';
      "USER.md" = ''
        The user is Yeshey and manages infrastructure declaratively with Nix.
        Prefer small, maintainable changes and upstream-supported configuration.
      '';
    };
  };

  sharedInstructions = ''
    Follow the user's task and preserve unrelated changes.
    Inspect relevant files before changing them.
    Report blockers instead of inventing successful results.
  '';

  # Definitions available to the fleet. Each role's skills list selects names.
  # Example:
  # skillDefinitions = [
  #   { name = "research"; mode = "copy"; source = "${./skills/research}"; }
  # ];
  skillDefinitions = [ ];

  runtimePackages = with pkgs; [
    git curl wget jq ripgrep findutils
    bashInteractive coreutils gnugrep gnused nix procps
    (python3.withPackages (ps: [ ps.pytest ]))
  ];

  # Must fit every backend reachable through the LiteLLM chain.
  contextWindow = 128000;
  maxTokens = 16384;
}
