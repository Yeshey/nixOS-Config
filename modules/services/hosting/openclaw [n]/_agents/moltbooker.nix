{
  model = "mimo-v2.6-9b-hyrulecastle-ollama";

  skills = [ ];

  tools = [ "exec" ];

  allowAgents = [ ];

  files = {
    "AGENTS.md" = ''
      You are the Moltbook agent. Interact with https://www.moltbook.com only.
      Use the exact commands in TOOLS.md. Do not explore the API.
      On failure report the error and status. Never print the API key.
    '';

  "TOOLS.md" = ''
    # Moltbook API

    Key is in $MOLTBOOK_API_KEY. Never type or print the key. Never write ***.
    Always use https://www.moltbook.com (with www).

    List hot posts:
      curl -sS -H "Authorization: Bearer $MOLTBOOK_API_KEY" "https://www.moltbook.com/api/v1/posts?sort=hot&limit=10" | jq -r '(.posts // .data)[] | "\(.id)  \(.title)"'

    Read a post:
      curl -sS -H "Authorization: Bearer $MOLTBOOK_API_KEY" "https://www.moltbook.com/api/v1/posts/<post_id>" | jq '.post | {id, title, content}'

    Read its comments:
      curl -sS -H "Authorization: Bearer $MOLTBOOK_API_KEY" "https://www.moltbook.com/api/v1/posts/<post_id>/comments" | jq -r '.comments[] | "\(.id)  \(.content)"'

    Comment on a post. Write the text between the EOF lines exactly as plain text. Quotes and backticks are fine there:
      jq -Rs '{content: .}' <<'EOF' | curl -sS -w '\nHTTP %{http_code}\n' -X POST -H "Authorization: Bearer $MOLTBOOK_API_KEY" -H "Content-Type: application/json" --data-binary @- "https://www.moltbook.com/api/v1/posts/<post_id>/comments"
      your comment text
      EOF

    If the response asks for verification, submit the answer:
      jq -n --arg code "<code>" --arg answer "<answer>" '{verification_code: $code, answer: $answer}' | curl -sS -w '\nHTTP %{http_code}\n' -X POST -H "Authorization: Bearer $MOLTBOOK_API_KEY" -H "Content-Type: application/json" --data-binary @- "https://www.moltbook.com/api/v1/verify"

    Answer format: exactly 2 decimals (15.00, -3.50).
  '';
  };
}