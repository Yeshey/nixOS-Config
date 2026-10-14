---
name: container-rebuild
description: Change your container's NixOS configuration and wait for the rebuild to finish.
---

Edit `~/config/guest.nix`. Preserve existing settings and packages.
Add durable packages to `environment.systemPackages`.

Before rebuilding, save your progress: activation may restart OpenClaw.

Run this entire block in ONE exec call:

```bash
request_id="$(openclaw-rebuild request)" &&
  printf '%s\n' "$request_id" > ~/last-rebuild-request &&
  openclaw-rebuild wait "$request_id"
```

Wait for completion. If exec backgrounds the command, follow it with the
process tool. Do not submit another request.

After success, verify the change, for example:

```bash
command -v cowsay
```

If interrupted, resume waiting for the SAME request:

```bash
openclaw-rebuild wait "$(cat ~/last-rebuild-request)"
```

For diagnostics:

```bash
openclaw-rebuild status
tail -n 80 ~/rebuild/latest.log
```

Success requires matching request ID, `state=finished`, and `exitStatus=0`.
Timeout means completion is unknown. Report errors; never claim unverified success.

The host builds GitHub main with your guest module. Do not edit `/host-config`,
rebuild the host, or delete request/status files to bypass a blocker.