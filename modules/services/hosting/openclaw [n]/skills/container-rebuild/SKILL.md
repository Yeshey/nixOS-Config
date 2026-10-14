---
name: container-rebuild
description: Install durable container packages or change the OpenClaw guest configuration, request a rebuild, and verify completion.
---

# Container configuration

Edit `~/config/guest.nix`, preserving existing settings. This is the writable
NixOS guest extension. For packages, add `pkgs.<name>` to
`environment.systemPackages`. The host fetches GitHub main and builds the
container with this module; do not edit `/host-config` or rebuild the host.

Before applying, save your progress in workspace files: activation can restart
OpenClaw and interrupt this tool call. Persistent files and rebuild status remain.

Request a rebuild using the existing exec tool:

```bash
openclaw-rebuild request
```

Save the printed request ID in a workspace file before waiting. Do not submit a
second request while one is pending or running.

```bash
openclaw-rebuild wait REQUEST_ID
```

Waiting polls every two seconds, times out after 65 minutes, and returns the
rebuild's exit status. If exec runs this in the background, use the process tool
to follow that same command. Do not start another rebuild to check progress.

If interrupted, recover using:

```bash
openclaw-rebuild status
cat ~/rebuild/latest.log
```

Only `state=finished`, matching `requestId`, and `exitStatus=0` confirm success.
Verify the requested change separately, for example `command -v cmatrix`.
Report failures accurately. A timeout means completion is unknown, not failure
of the build. Do not delete pending requests or status files to bypass a blocker.
