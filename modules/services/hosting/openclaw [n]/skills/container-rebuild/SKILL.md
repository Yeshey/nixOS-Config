---
name: container-rebuild
description: Change and test the OpenClaw container using its own NixOS-Config checkout.
---

Work in `~/projects/nixOS-Config`.
Edit `modules/services/hosting/openclaw [n]/_playground/guest.nix`.
Helpers can be plain `.nix` files in that folder, imported explicitly.
Existing dendritic modules are available as `inputs.self.modules.nixos.<name>`
in modules that accept `{ inputs, ... }`.

Change only `_playground` unless Yeshey explicitly asks for another repository
change. Never put decrypted secrets or private keys in the repository.
The guest's SOPS module decrypts declared secrets during activation.
The network is shared with the host: test services must use unused ports.

Save your work, then run ONE command:

```bash
openclaw-rebuild apply
```

This builds the local checkout, including uncommitted changes, activates only
the container, prints recent logs, and exits with the result. No pull, commit,
push, or host deployment occurs. Do not edit files during the build.
If exec backgrounds it, follow that process. Verify the change after success.

If activation interrupts the session:

```bash
openclaw-rebuild status
openclaw-rebuild wait "$(cat ~/last-rebuild-request)"
```

Read `~/rebuild/latest.log` for full errors. Matching `requestId`,
`state=finished`, and `exitStatus=0` confirm completion. `applied=true` with
a nonzero exit status means activation completed but a later step failed.
Timeout means completion is unknown. Do not submit duplicate requests.
