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
        Shell commands run as openclaw inside the Skyloft NixOS container.
        The host Nix configuration is read-only at /host-config.
        Use ~/projects for checkouts and ~/config for configuration proposals.
        Host deployment configuration is applied by Yeshey, not by the agent.
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

    You run as openclaw inside a NixOS container.
    Your home is writable; use ~/projects for project checkouts.
    /host-config is a read-only snapshot of the host configuration.

    To add persistent packages or change guest settings, edit ~/config/guest.nix.
    This is a NixOS module that extends the existing container configuration.
    For example:
      { pkgs, ... }: {
        environment.systemPackages = [ pkgs.fd ];
      }

    Save your progress before requesting a rebuild; the Gateway may restart.
    Request it with: touch ~/config/rebuild.request
    Check the result in ~/rebuild/latest.log. Builds may take several minutes.
    Submit one request at a time.
    Outer container mounts and host services require Yeshey to change them.
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
