---
name: container-rebuild
description: Change your container configuration, rebuild it, and publish the tested playground to GitHub.
---

Edit `~/config/guest.nix`, preserving unrelated settings. This aliases
`~/config/playground/guest.nix-data`. Add packages to `environment.systemPackages`.

Put helper files in `~/config/playground/`. Use `.nix-data` for Nix helper modules
and import them explicitly from `guest.nix-data`. Only imported modules affect
NixOS. Keep paths relative. Do not put secrets, symlinks, or Git repositories here.
The entire playground, including added and deleted files, is committed to the
public GitHub repository after successful build and activation.

Save your progress before applying: activation may restart OpenClaw.
Run this whole block in ONE exec call:

```bash
request_id="$(openclaw-rebuild request)" &&
  printf '%s\n' "$request_id" > ~/last-rebuild-request &&
  openclaw-rebuild wait "$request_id"
```

Wait for completion. If exec backgrounds the command, follow it with process.
Do not submit another request while one is pending or running.

Success requires the matching request ID, `state=finished`, `exitStatus=0`,
`applied=true`, and `published=true`. Verify the requested change separately,
for example `command -v cowsay`.

If interrupted, resume the SAME request:

```bash
openclaw-rebuild wait "$(cat ~/last-rebuild-request)"
```

For diagnostics:

```bash
openclaw-rebuild status
tail -n 80 ~/rebuild/latest.log
```

A publication failure can leave the guest applied but GitHub unchanged. Report
that distinction. Timeout means completion is unknown. Do not claim success,
force-push, delete status files, or rebuild the host.

The host owns GitHub authentication and commits. You do not need its token.
