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
    "sessions_spawn"
    "sessions_yield"
    "subagents"
  ];

  prompt = ''
    Maintain the LiteLLM configuration in your own checkout at
    ~/projects/nixOS-Config/modules/services/hosting/litellm [N]/litellm.nix.
    Inspect that file and the current Git diff first. Preserve unrelated edits.

    Check repository state, pull latests changes.

    Read memory/litellm-maintenance.md in your workspace at the start of each run.
    You may create and update this file to track pending integrations, required
    credentials or host changes, tested models, dated failures, and open PR URLs.
    Review pending items before repeating research. Keep entries concise, update
    resolved items, and never store secret values.

    This task authorizes changes to that LiteLLM module, its adjacent README.md,
    and the OpenClaw _playground folder. It authorizes pushing a dedicated
    proposal branch and opening a pull request for review. It does not authorize
    pushing non-playground changes directly to main, merging a PR, deploying
    the host, or changing the host's encrypted secrets or credential wiring.

    Use the model-benchmarks skill to compare configured models and promising
    new models available through free API endpoints. You may repair that skill
    inside _playground when official endpoints or schemas change.

    Search for current free API models, prioritizing providers already configured.
    Verify exact model IDs, API URLs, pricing, and quotas against official provider
    documentation. If a provider requires new credentials or host
    wiring, or a new provider with a free tier that could be used is found,
    report what is needed and leave that integration pending.
    ALWAYS check with official sources. third party sources may be outdated or
    wrong, treat those as suggestions, and if you can't find official information,
    then test the endpoints.

    Use subagents when handy, for example for research, probing endpoints, 
    comparing agents through the benchmarks, etc.

    Make focused model-list and fallback-chain improvements only when supported
    by current documentation and observed API behavior. Preserve
    strong-fallback-chain and weak-fallback-chain aliases and known working
    fallback coverage. Distinguish invalid model IDs from expired credentials,
    exhausted quotas, rate limits, and temporary provider failures.
    Respect Retry-After and avoid repeated retry loops.

    Probe at most five candidate models across the entire run, using small
    requests within documented free quotas. Probe concrete aliases rather than
    only fallback chains. Count a candidate as working only when response or
    service evidence confirms it served the request. A successful fallback does
    not prove the requested candidate works.

    Test justified configuration changes using the container-rebuild skill.
    Use modules/services/hosting/openclaw [n]/_playground/litellm-test.nix
    to import inputs.self.modules.nixos.litellm from this checkout, bound to
    127.0.0.1:14001 with openFirewall=false.

    Run openclaw-rebuild apply once to apply the prepared test configuration.
    Follow that request to completion before submitting another request.
    Then verify service/API health and perform bounded real inference tests.
    HTTP 400, authentication errors, and a loaded model catalog do not prove
    inference works. Record status codes and sanitized errors.
    Production LiteLLM on port 4000 and OpenClaw's provider URL must stay unchanged.
    After testing, disable the temporary LiteLLM test service in the playground
    configuration without deleting the test module or unrelated configuration.
    Apply that cleanup through one additional rebuild. If no justified changes are needed, skip rebuilds and unnecessary PRs.

    The rebuild helper automatically publishes only the applied _playground.
    Use the github skill to commit only this task's LiteLLM module and adjacent
    README changes, push a dedicated proposal branch, and open a PR for Yeshey.
    Exclude unrelated changes and playground changes published by the helper.
    Telegram delivery is handled automatically.
  '';
}