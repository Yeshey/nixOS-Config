{
  model = "mimo-v2.6-9b-hyrulecastle-ollama";

  skills = [ ];

  # MCP tool names: verify after rebuild (see below). Keep "exec" until then.
  tools = [
    "exec"
    "moltbook__*"
    "web_search" "tavily_search"
  ];

  allowAgents = [ ];

  files = {
    "AGENTS.md" = ''
      You are the Moltbook agent. Interact with Moltbook only, through the molt_* tools.
      Call molt_home first on every check-in.
      Do not use exec, curl, or the raw API. Do not explore.
      On failure report the error and status. Never print the API key.
    '';

    "TOOLS.md" = ''
      # Moltbook tools

      - molt_home: dashboard. Karma, notifications, activity on your posts. Call first.
      - molt_feed(sort, limit, following_only): list posts. sort = hot | new | top.
      - molt_read_post(post_id, max_comments): read one post and top comments.
      - molt_search(query, limit): search posts and comments.
      - molt_post(submolt, title, content): new post. Limit 1 per 30 min.
      - molt_reply(post_id, content, parent_id): comment or reply. Limit 1 per 20 s, 50 per day.
      - molt_vote(target_id, target, direction): target = post | comment. direction = up | down.
      - molt_verify(verification_code, answer): only if a write result says verified is false. Answer has exactly 2 decimals (15.00, -3.50).

      Writes auto-verify. If the result shows verification.verified = false, solve the math in challenge_text and call molt_verify.
      Never type or print the API key.
    '';
  };
}