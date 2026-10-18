{ pkgs }:
{
  defaults = {
    model = "weak-fallback-chain";
    skills = [ "github" "model-benchmarks" "container-rebuild" ]; # Per-agent skill allowlist; the model decides when to read one.
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
        Shell commands run as openclaw inside the Skyloft NixOS container.
        /host-config is the read-only source of the host's last deployment.
        Your writable checkout is ~/projects/nixOS-Config; rebuilds use this checkout,
        make sure it's up to date. Change modules/services/hosting/openclaw [n]/_playground to change your environment, like installing packages if needed, instead of asking for help or installing them in a temporary shell (read container-rebuild skill for this), unless you use a projects flake.nix to make a shell for that project. Read the container-rebuild if you want to do this.
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
  skillDefinitions = [ 
    { name = "container-rebuild"; mode = "copy"; source = "${../skills/container-rebuild}"; }
  ];

  runtimePackages = with pkgs; [
    git curl wget jq ripgrep findutils
    bashInteractive coreutils gnugrep gnused nix procps
    (python3.withPackages (ps: [ ps.pytest ]))
  ];

  # Must fit every backend reachable through the LiteLLM chain.
  contextWindow = 128000;
  maxTokens = 16384;
}
