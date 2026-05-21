# UniBo HPC — Standalone Home Manager

Manages `joaofilipe.silvade` on `giano.cs.unibo.it` (L40 cluster) via
home-manager + **nix-user-chroot** (user-namespace bind-mount, no root required).

---

## Architecture

Real `$HOME` (`/home/students/joaofilipe.silvade`) is ephemeral — the cluster
resets it periodically and also restores certain dotfiles (e.g. `.bash_profile`)
on every login. Everything persistent lives in:

```
/scratch.hpc/joaofilipe.silvade/   ($SCR)
├── .setup/          ← this repo
├── .nix-profile/    ← HM-managed profile (symlink farm)
├── .config/
├── .local/
├── .cache/
├── bootstrap/
│   └── nix-user-chroot   ← static musl binary, survives home wipes
├── nix-root/
│   └── nix/         ← actual nix store, mounted as /nix inside chroot
└── bin/
    ├── nix-enter        ← chroot entry-point (real file, not nix symlink)
    ├── bootstrap-nuc    ← downloads nix-user-chroot
    └── bootstrap-home   ← fixes real ~/.bashrc after home wipe
```

Home Manager writes dotfiles to `$SCR` since `home.homeDirectory = $SCR`.

### Why nix-user-chroot (not proot / nix-portable)

User namespaces are enabled on this cluster (`CONFIG_USER_NS=y`,
`unprivileged_userns_clone=1`) and `unshare --user --map-root-user` works.
`nix-user-chroot` only maps the current UID as root inside the namespace —
it does **not** need `/etc/subuid`/`/etc/subgid` entries (those are needed by
bubblewrap/bwrap for full UID-range mapping, which is why the default nix
sandbox fails). Result: real unmodified nix, no ptrace overhead.

### Why scripts in `home.activation`, not `home.file`

`home.file` entries are **symlinks into `/nix/store`**. Outside nix-user-chroot,
`/nix/store` does not exist — those symlinks are dead. The bootstrap scripts
(`nix-enter`, `bootstrap-home`, etc.) must be executable before entering the
chroot, so they are written as real files via `home.activation` using
`pkgs.writeTextFile` (which uses `#!/usr/bin/env bash`, not a nix store
shebang) and `install`.

### Why `path:` URL for `home-manager switch`

`git+file://` URLs make nix read `flake.lock` from the pinned git revision.
`path:` reads from the working tree, so a patched `flake.lock` is visible
without committing.

---

## One-time bootstrap (new account or full wipe of `$SCR`)

### 0 — Get a compute node

The login node enforces cgroup memory limits that OOM-kill nix evaluation
even when `htop` shows free RAM:

```bash
srun --pty --mem=8G -c 2 /bin/bash
```

### 1 — Download nix-user-chroot

```bash
SCR=/scratch.hpc/joaofilipe.silvade
mkdir -p "$SCR/bootstrap" "$SCR/nix-root"
curl -fsSL \
  "https://github.com/nix-community/nix-user-chroot/releases/latest/download/nix-user-chroot-x86_64-unknown-linux-musl" \
  -o "$SCR/bootstrap/nix-user-chroot"
chmod +x "$SCR/bootstrap/nix-user-chroot"
```

### 2 — Install nix (no-daemon, inside the chroot)

```bash
$SCR/bootstrap/nix-user-chroot "$SCR/nix-root" \
  bash -c 'curl -L https://nixos.org/nix/install | bash -s -- --no-daemon'
```

### 3 — Enter the nix environment manually (first time only)

```bash
$SCR/bootstrap/nix-user-chroot "$SCR/nix-root" \
  env HOME="$SCR" \
      USER="joaofilipe.silvade" \
      XDG_STATE_HOME="$SCR/.local/state" \
      XDG_CONFIG_HOME="$SCR/.config" \
      XDG_DATA_HOME="$SCR/.local/share" \
  bash -l

# inside the chroot — source nix
export PATH="$SCR/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
source "$SCR/.nix-profile/etc/profile.d/nix.sh" 2>/dev/null || true
```

### 4 — Clone `.setup` if missing

```bash
[ ! -d "$SCR/.setup" ] && git clone <your-setup-repo-url> "$SCR/.setup"
cd "$SCR/.setup"
```

### 5 — Fix the flake lock

The dev machine runs nix ≥ 2.24 which omits `narHash` from `path:` inputs in
`flake.lock`. The nix installed by nixos.org's installer is nix 2.20.x, which
requires `narHash`. Strip the stale entries so nix regenerates them:

```bash
python3 -c "
import json
with open('flake.lock') as f: l = json.load(f)
for k in ['packages', 'secrets']:
    l['nodes'].pop(k, None)
    l['nodes']['root']['inputs'].pop(k, None)
with open('flake.lock', 'w') as f: json.dump(l, f, indent=2)
print('stripped mutable locks for: packages, secrets')
"
```

This must be repeated after every `nix flake update` on the dev machine until
both machines agree on the lock format.

### 6 — First home-manager switch

```bash
home-manager switch --flake "path:$SCR/.setup#unibo" --impure
```

This writes the nix profile, dotfiles, and — via `home.activation` — the real
bootstrap scripts (`nix-enter`, `bootstrap-home`, etc.) to `$SCR/bin/`.

### 7 — Fix the real `~/.bashrc` (once after each home reset)

```bash
bash "$SCR/bin/bootstrap-home"
```

This writes `[ -f "$SCR/.bashrc" ] && . "$SCR/.bashrc"` to the real
`~/.bashrc`. On every subsequent SSH login, bash sources `$SCR/.bashrc` which
contains the `nix-enter` exec guard.

### 8 — Exit and re-login

```bash
exit   # leave the manually entered chroot
```

SSH in again — the login should now automatically enter the nix-user-chroot
and drop into zsh with the full HM environment.

---

## After home wipe (real `$HOME` reset, `$SCR` intact)

`$SCR` survives all wipes. Only the real home is reset. Steps needed:

```bash
# 1. Get a compute node if doing a full update; for just restoring login, skip
srun --pty --mem=8G -c 2 /bin/bash

# 2. Enter chroot manually (nix-enter doesn't exist yet in real home context)
/scratch.hpc/joaofilipe.silvade/bootstrap/nix-user-chroot \
  /scratch.hpc/joaofilipe.silvade/nix-root \
  env HOME=/scratch.hpc/joaofilipe.silvade \
      USER=joaofilipe.silvade \
      XDG_STATE_HOME=/scratch.hpc/joaofilipe.silvade/.local/state \
      XDG_CONFIG_HOME=/scratch.hpc/joaofilipe.silvade/.config \
      XDG_DATA_HOME=/scratch.hpc/joaofilipe.silvade/.local/share \
  bash -l

# 3. Restore ~/.bashrc redirect
bash /scratch.hpc/joaofilipe.silvade/bin/bootstrap-home

# 4. Exit and re-login — auto-enter works again
exit
```

No `home-manager switch` needed unless the config actually changed.

---

## Subsequent updates

```bash
update
# expands to: home-manager switch --flake path:/scratch.hpc/joaofilipe.silvade/.setup#unibo --impure
```

If the dev machine pushed a new `flake.lock` without `narHash` for
`packages`/`secrets`, re-run the python strip from step 5 first.

---

## GPU / experiment shells

```bash
cd $SCR/alignment-faking

# Request GPU node first
srun -p l40 --gres=gpu:1 --time=04:00:00 --pty bash

nix develop                  # vllm-cuda-l40 (default)
nix develop .#vllm-cuda      # any CUDA GPU
nix develop .#vllm           # CPU only
nix develop .#bnb            # QLoRA fine-tuning
```

---

## Gotchas & notes

**Compute node required for switches** — the login node OOM-kills nix
evaluation via cgroup limits even when `htop` shows free RAM. Always run
`home-manager switch` on a compute node (`srun --pty --mem=8G -c 2 /bin/bash`).

**`~/.bash_profile` is cluster-managed** — the cluster restores its default
`.bash_profile` on every login. Do not rely on it. The chain that works:
real `~/.bashrc` → sources `$SCR/.bashrc` → `$SCR/.bashrc` execs `nix-enter`.
`bootstrap-home` sets up the real `~/.bashrc` link; it survives resets.

**`home.file` = dead symlinks outside chroot** — all `home.file` entries are
symlinks into `/nix/store` which does not exist outside nix-user-chroot. Any
file that needs to be executable before entering the chroot (like `nix-enter`)
must be written via `home.activation` using `pkgs.writeTextFile` (for the
`#!/usr/bin/env bash` shebang) + `install`.

**`pkgs.writeShellScript` / `pkgs.writeScriptBin` are unusable here** — they
embed a `#!/nix/store/.../bash` shebang, which is invalid outside the chroot.
Always use `pkgs.writeTextFile { executable = true; text = "#!/usr/bin/env bash\n..."; }`.

**`path:` URL required for switch** — use `home-manager switch --flake "path:$SCR/.setup#unibo"`,
not the bare directory. `path:` reads `flake.lock` from the filesystem (sees
your edits); `git+file://` reads from the pinned git rev (misses them).

**`system-cli` / `zed-editor-host` excluded** — `system-cli` adds
`pkgs.home-manager` (nixpkgs version) which conflicts with
`programs.home-manager.enable` (home-manager-input version) in `standalone-hm`.
`zed-editor-host` is a GUI app; headless cluster won't build its deps cleanly.

**`pkgs.local` overlay** — defined in `modules/hosts/unibo/configuration.nix`
since there is no NixOS layer to inject it. Required by `safe-rm` and any
other module referencing `pkgs.local.coreutils-with-safe-rm`.

**flake.lock path-input narHash mismatch** — nix 2.20 (cluster) requires
`narHash` in the lock for `path:` inputs; nix ≥ 2.24 (dev machine) omits it.
Strip the `packages`/`secrets` nodes from the lock before switching on the
cluster. After switching, commit the regenerated lock (with narHashes) so
subsequent pulls don't need the strip step.

**Model weights cache** — set `HF_HOME=$SCR/.cache/huggingface`.