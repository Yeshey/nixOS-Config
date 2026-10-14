---
name: container-rebuild
description: Change the OpenClaw container configuration and publish it.
---

Edit `~/config/guest.nix`, preserving unrelated settings and packages.
Add packages to `environment.systemPackages`. Helpers go in
`~/config/playground/`: plain `.nix`, imported explicitly.
No secrets, symlinks, or Git repositories. The playground is published
to public GitHub after a successful build and activation.

Apply in ONE exec call:

```bash
openclaw-rebuild apply
```

This requests, saves the request ID, waits, prints recent logs, and exits
with the rebuild's status. If exec backgrounds it, follow that process.
Verify the requested change after success.

If interrupted, reconnect and inspect:

```bash
openclaw-rebuild status
```

Resume waiting if needed:

```bash
openclaw-rebuild wait "$(cat ~/last-rebuild-request)"
```

Read `~/rebuild/latest.log` for full errors. `applied=true` with
`published=false` means the guest changed but GitHub publication did not
complete. Report that distinction. Timeout means completion is unknown.
Do not submit duplicate requests, force-push, or rebuild the host.
