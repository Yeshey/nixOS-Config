# Clean-slate agent. `inheritDefaults = false` tells openclaw.nix to skip the
# common tools/skills/files entirely, so this agent gets only what it declares
# here plus the always-required attributes (model, instructions, allowAgents,
# files, AGENTS.md).
{
  inheritDefaults = false;

  model = "mimo-v2.6-9b-hyrulecastle-ollama";

  instructions = ''
    You are the Moltbook agent. Your only job is to interact with the Moltbook
    API at https://www.moltbook.com via the exec tool.

    Read recent posts first, then contribute useful, specific comments or
    replies, or create an original post if you have something worth sharing.
    Avoid duplicate or generic engagement. Respect rate limits.

    Prefer the helper scripts in your workspace (`./moltbook-comment`,
    `./moltbook-verify`) over hand-writing curl for comments — they handle
    JSON quoting and verification for you.

    Never claim an action succeeded unless the API returned a success response.
    If a request fails, report the exact error and the HTTP status code.
  '';

  # No skills are loaded.
  skills = [ ];

  # Only the exec tool is needed: it is how curl and the helper scripts run.
  tools = [ "exec" ];

  # This agent cannot spawn subagents.
  allowAgents = [ ];

  # These files in the workspace will be chmod +x by openclaw.nix.
  executableFiles = [ "moltbook-comment" "moltbook-verify" ];

  files = {
    "SOUL.md" = ''
      Be precise. Distinguish API success from API failure.
      Respect rate limits. Do not retry aggressively.
    '';

    "IDENTITY.md" = "You are the Moltbook interaction agent.";

    "TOOLS.md" = ''
      Use the exec tool. The API key is in $MOLTBOOK_API_KEY.

      All URLs use https://www.moltbook.com (always `www` — without it,
      redirects strip the Authorization header).

      Read recent posts:
        curl -s -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
          "https://www.moltbook.com/api/v1/posts?sort=hot&limit=10"

      Read a specific post with its comments:
        curl -s -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
          "https://www.moltbook.com/api/v1/posts/{post_id}"

      Comment on a post (recommended — use the helper script):
        ./moltbook-comment "{post_id}" "your comment text here"

        The script posts the comment and prints the raw response. If
        `verification_required: true` appears in the response, it also
        prints the verification code and challenge text — follow the
        printed instructions.

      Submit a verification answer:
        ./moltbook-verify "{verification_code}" "<answer>"

        The answer must be a number with exactly 2 decimal places
        (e.g. 15.00, -3.50, 84.00).

      NEVER paste the API key into a command — always reference
      $MOLTBOOK_API_KEY.
    '';

    "moltbook-comment" = ''
      #!/usr/bin/env bash
      set -euo pipefail

      post_id="''${1:?usage: moltbook-comment <post_id> <text>}"
      shift
      text="$*"

      if [ -z "''${MOLTBOOK_API_KEY:-}" ]; then
        echo "ERROR: MOLTBOOK_API_KEY is not set" >&2
        exit 1
      fi

      response=$(jq -Rs '{content: .}' <<<"$text" | curl -sS -X POST \
        -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
        -H "Content-Type: application/json" \
        --data-binary @- \
        "https://www.moltbook.com/api/v1/posts/$post_id/comments")

      printf '%s\n' "$response"

      if command -v jq >/dev/null 2>&1; then
        code=$(printf '%s' "$response" | jq -r '.comment.verification.verification_code // empty' 2>/dev/null || true)
        challenge=$(printf '%s' "$response" | jq -r '.comment.verification.challenge_text // empty' 2>/dev/null || true)
        if [ -n "$code" ]; then
          echo
          echo "=== VERIFICATION REQUIRED ==="
          echo "code: $code"
          echo "challenge: $challenge"
          echo "Solve the math problem, then run:"
          echo "  ./moltbook-verify '$code' '<answer.00>'"
        fi
      fi
    '';

    "moltbook-verify" = ''
      #!/usr/bin/env bash
      set -euo pipefail

      code="''${1:?usage: moltbook-verify <verification_code> <answer>}"
      answer="''${2:?usage: moltbook-verify <verification_code> <answer>}"

      if [ -z "''${MOLTBOOK_API_KEY:-}" ]; then
        echo "ERROR: MOLTBOOK_API_KEY is not set" >&2
        exit 1
      fi

      jq -n --arg code "$code" --arg answer "$answer" \
        '{verification_code: $code, answer: $answer}' \
        | curl -sS -X POST \
            -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
            -H "Content-Type: application/json" \
            --data-binary @- \
            "https://www.moltbook.com/api/v1/verify"
      echo
    '';
  };
}