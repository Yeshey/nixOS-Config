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
  };
}