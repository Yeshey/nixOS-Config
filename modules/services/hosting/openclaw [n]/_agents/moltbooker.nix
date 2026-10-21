{
  model = "mimo-v2.6-9b-hyrulecastle-ollama";

  skills = [ ];

  tools = [ "exec" ];

  allowAgents = [ ];

  executableFiles = [
    "moltbook-list"
    "moltbook-read"
    "moltbook-comment"
    "moltbook-verify"
  ];

  files = {
    "AGENTS.md" = ''
      You are the Moltbook agent. Interact with https://www.moltbook.com only.
      Never use curl or jq directly. Use as little tool calls as possible.
    '';

    "TOOLS.md" = ''
      # Moltbook commands

      List posts:        ./moltbook-list [N]
      Read a post:       ./moltbook-read <post_id>
      Comment:           ./moltbook-comment <post_id> "text"
      Verify (if asked): ./moltbook-verify '<code>' '<answer>'

      Order: list → read 1-2 → comment → verify only if asked.
      Verify answer: exactly 2 decimals (15.00, -3.50).
    '';

    "moltbook-list" = ''
      #!/usr/bin/env bash
      set -euo pipefail

      limit="''${1:-10}"
      : "''${MOLTBOOK_API_KEY:?ERROR: MOLTBOOK_API_KEY is not set}"

      curl -sS -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
        "https://www.moltbook.com/api/v1/posts?sort=hot&limit=$limit" \
      | jq -r '
          def a: (.author.name // .author.username // .author.handle // "?");
          (.posts // .data // .) as $p
          | (if ($p | type) == "array" then $p else [$p] end)[]
          | "\(.id)  \(a)  \(((.title // .content // .body // "") | tostring | gsub("\n"; " ") | .[0:160]))"
        '
    '';

    "moltbook-read" = ''
      #!/usr/bin/env bash
      set -euo pipefail

      post_id="''${1:?usage: moltbook-read <post_id>}"
      : "''${MOLTBOOK_API_KEY:?ERROR: MOLTBOOK_API_KEY is not set}"

      curl -sS -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
        "https://www.moltbook.com/api/v1/posts/$post_id" \
      | jq -r '
          def a: (.author.name // .author.username // .author.handle // "?");
          .post as $p
          | "POST \($p.id) by \($p | a)",
            (($p.title // "") | tostring),
            "",
            (($p.content // "") | tostring),
            "",
            "comments: \($p.comment_count // 0)"
        '
    '';

    "moltbook-comment" = ''
      #!/usr/bin/env bash
      set -euo pipefail

      post_id="''${1:?usage: moltbook-comment <post_id> <text>}"
      shift
      text="$*"
      : "''${MOLTBOOK_API_KEY:?ERROR: MOLTBOOK_API_KEY is not set}"

      body_file="$(mktemp)"
      trap 'rm -f "$body_file"' EXIT

      status="$(jq -Rs '{content: .}' <<<"$text" | curl -sS \
        -o "$body_file" -w '%{http_code}' \
        -X POST \
        -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
        -H "Content-Type: application/json" \
        --data-binary @- \
        "https://www.moltbook.com/api/v1/posts/$post_id/comments")"

      body="$(cat "$body_file")"

      if [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
        echo "FAILED: HTTP $status"
        printf '%s\n' "$body" | jq -r '.error // .message // .' 2>/dev/null || printf '%s\n' "$body"
        exit 1
      fi

      code="$(printf '%s' "$body" | jq -r '.comment.verification.verification_code // empty' 2>/dev/null || true)"
      if [ -n "$code" ]; then
        challenge="$(printf '%s' "$body" | jq -r '.comment.verification.challenge_text // empty' 2>/dev/null || true)"
        echo "COMMENT POSTED but VERIFICATION REQUIRED."
        echo "code: $code"
        echo "challenge: $challenge"
        echo "Run: ./moltbook-verify '$code' '<answer with 2 decimals>'"
        exit 0
      fi

      echo "OK: comment posted to $post_id"
    '';

    "moltbook-verify" = ''
      #!/usr/bin/env bash
      set -euo pipefail

      code="''${1:?usage: moltbook-verify <verification_code> <answer>}"
      answer="''${2:?usage: moltbook-verify <verification_code> <answer>}"
      : "''${MOLTBOOK_API_KEY:?ERROR: MOLTBOOK_API_KEY is not set}"

      body_file="$(mktemp)"
      trap 'rm -f "$body_file"' EXIT

      status="$(jq -n --arg code "$code" --arg answer "$answer" \
        '{verification_code: $code, answer: $answer}' \
        | curl -sS -o "$body_file" -w '%{http_code}' \
            -X POST \
            -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
            -H "Content-Type: application/json" \
            --data-binary @- \
            "https://www.moltbook.com/api/v1/verify")"

      body="$(cat "$body_file")"

      if [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
        echo "FAILED: HTTP $status"
        printf '%s\n' "$body" | jq -r '.error // .message // .' 2>/dev/null || printf '%s\n' "$body"
        exit 1
      fi

      echo "OK: verification accepted"
    '';
  };
}