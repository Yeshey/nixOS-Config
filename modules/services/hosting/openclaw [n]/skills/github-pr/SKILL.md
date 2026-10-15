---
name: github-pr
description: Load this skill when the task requires pushing a branch or opening a pull request on GitHub as the GitHub App bot. Covers GitHub App installation-token auth via gh, safe branch/commit hygiene, and PR creation with gh. Use whenever the agent must authenticate as the App or propose changes via PR.
---

Authenticate as the GitHub App:
- App ID: 5325279
- Installation ID: 171592385
- Private key: /run/openclaw-secrets/github-app-key

Use installed gh-token to generate an installation token. Capture its token
field into GH_TOKEN without printing it. Generate a fresh token when needed;
never persist tokens in Git URLs, repository files, or shell startup files.

Use gh for pull requests and gh auth git-credential for HTTPS Git access.
Do not install authentication libraries, invent JWT implementations, or use
personal-account authentication. If required tools are missing, report that.

Preserve unrelated work. Use a dedicated proposal branch and inspect the
complete diff against the target branch before pushing. Commit only files
authorized by the task. Never push to main or merge a PR.

The rebuild helper publishes playground changes separately. Do not include
those changes in a proposal unless the task explicitly requires them.

Open the PR with a clear description of changes, validation, and blockers.
Report its URL. If an operation fails, report the exact sanitized error.