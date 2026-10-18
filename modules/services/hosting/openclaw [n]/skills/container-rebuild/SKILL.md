---
name: container-rebuild
description: Change the OpenClaw container, apply its configuration, and record the applied playground on GitHub.
---

Work in `~/projects/nixOS-Config`.
Edit `modules/services/hosting/openclaw [n]/_playground/guest.nix`.
Helpers can be plain `.nix` files in that folder, imported explicitly.
Existing dendritic modules are available as `inputs.self.modules.nixos.<name>`
in modules that accept `{ inputs, ... }`.

You have access to `nix` and `nix_versions` tools to help with the nix configuration.

Change only `_playground` unless Yeshey explicitly asks for another repository
change. Never put decrypted secrets or private keys in the repository.
No symlinks or nested Git repositories in `_playground`. Its contents are public.
The guest's SOPS module decrypts declared secrets during activation.
The network is shared with the host: test services must use unused ports.

Save your work, then run ONE command:

```bash
openclaw-rebuild apply
```

This snapshots the local checkout, builds and activates only the container,
then commits and pushes the applied `_playground` snapshot to GitHub `main`.
Other repository paths and local branch history are not published. The agent
checkout is not pulled, reset, or committed by the helper. Do not edit it during
the operation. Let the helper publish; do not commit or push manually.
If exec backgrounds it, follow that process. Verify the change after success.

If activation interrupts the session:

```bash
openclaw-rebuild status
openclaw-rebuild wait "$(cat ~/last-rebuild-request)"
```

Read `~/rebuild/latest.log` for full errors. Matching `requestId`,
`state=finished`, `exitStatus=0`, `applied=true`, and `published=true` confirm
completion. `commit` identifies the GitHub revision.
`applied=true` with `published=false` means the guest changed but publication
failed; report the exact error. The host retains the publication checkout.
Do not force-push, overwrite unrelated changes, or rebuild the host.
Timeout means completion is unknown. Do not submit duplicate requests.
