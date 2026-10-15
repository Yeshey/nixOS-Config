{
  name = "LiteLLM maintenance";
  enabled = true;
  agent = "orchestrator";
  cron = "0 9 * * 1";
  timezone = "Europe/Lisbon";
  session = "session:litellm-maintenance";
  telegramChatId = "1173067555";
  timeoutSeconds = 7200;
  tools = [
    "ls"
    "read"
    "write"
    "edit"
    "apply_patch"
    "exec"
    "process"
    "web_search"
    "tavily_search"
    "tavily_extract"
    "message"
  ];

  prompt = ''
    Maintain the LiteLLM configuration in your own checkout at
    ~/projects/nixOS-Config/modules/services/hosting/litellm [N]/litellm.nix.
    Inspect that exact path. Preserve unrelated edits.
    This task authorizes local changes to that LiteLLM module and the OpenClaw
    _playground folder. It authorizes committing the LiteLLM module changes on
    a dedicated branch and opening a pull request for review. It does not
    authorize pushing non-playground changes directly to GitHub main, merging
    the pull request, or a host deployment.

    Use the model-benchmarks skill to compare candidate models and possible new
    cutting edge models available in free endpoints to add to the chains.
    You may repair that skill inside _playground when official endpoints or
    schemas change.

    Search the web for current free API models supported by different providers.
    Verify model IDs, API URLs, pricing and quotas against official provider
    documentation.
    Report any newly required credentials instead of inventing keys or changing
    the host's encrypted secrets.

    Make focused local model-list and fallback-chain improvements only when
    supported by current documentation and observed API behavior. Preserve
    strong-fallback-chain and weak-fallback-chain aliases and known working
    fallback coverage. Distinguish dead model IDs from expired credentials,
    exhausted quotas, rate limits and temporary provider failures. Respect
    Retry-After and avoid repeated retry loops. Probe at most five candidate
    models per run with small requests using documented free quotas.
    Probe concrete model aliases rather than only fallback chains. Count a
    candidate as working only when the response or service evidence confirms
    it served the request; a successful fallback does not prove that candidate
    works.

    Test changes using the existing container-rebuild skill. Use
    modules/services/hosting/openclaw [n]/_playground/litellm-test.nix
    to import inputs.self.modules.nixos.litellm from this checkout, bound to
    127.0.0.1:14001 with openFirewall=false.

    Run `openclaw-rebuild apply` once after preparing changes, follow that same
    request to completion, then verify service/API health and make bounded
    real model requests. HTTP 400, auth errors and a loaded model catalog do
    not prove inference works. Report status codes and sanitized errors.
    Production LiteLLM on port 4000 and OpenClaw's provider URL must stay unchanged.

    The rebuild helper automatically publishes only the applied _playground.
    After testing, use the github skill to commit only this task's LiteLLM
    module and adjacent README changes. Push a dedicated proposal branch,
    and open a pull request for Yeshey to review. Exclude unrelated changes
    and playground changes already published by the helper.

    Maintain modules/services/hosting/litellm [N]/README.md beside litellm.nix
    with a ranked shortlist of configured models. This task also authorizes
    editing that README and including its changes in the same proposal PR.
    Keep fallback-chains order consistent with the documented ranking,
    accounting for provider reliability, quotas, and useful fallback diversity.

    Don't forget you can delegate subagents to help with small tasks.

    Disable your local litellm-test.nix when you finish, use it only for tests.

    Telegram delivery is handled automatically.
  '';
}