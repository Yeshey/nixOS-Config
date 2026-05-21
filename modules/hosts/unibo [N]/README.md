# unibo — HPC Cluster Setup via `nix-user-chroot`

**Host:** `giano` (UniBo HPC)  
**User:** `joaofilipe.silvade`  
**Persistent storage:** `/scratch.hpc/joaofilipe.silvade` (`$SCR`)  
**Real home (`$HOME`):** ephemeral — wiped periodically by cluster admins

## How this works

[`nix-user-chroot`](https://github.com/nix-community/nix-user-chroot) uses Linux
user-namespaces to bind-mount a directory of your choice as `/nix` inside a chroot
shell. This gives you a fully standard Nix environment (real `/nix/store`, daemon-less
single-user install) without root. NVIDIA/CUDA access is **unaffected** — the
namespace only remounts `/nix`; hardware devices, kernel modules, and
`/dev/nvidia*` are all visible as normal.

Everything persistent lives under `$SCR`:

```
$SCR/
├── .nix/                 ← the Nix store (bind-mounted as /nix inside chroot)
├── .setup/               ← your NixOS config repo
├── .config/              ← home-manager writes configs here (nix.conf, etc.)
├── .nix-profile -> ...   ← single-user nix profile
├── bin/                  ← bootstrap + entry scripts (managed by home-manager)
│   ├── nix-enter         ← enter the chroot (primary entry-point post-setup)
│   ├── bootstrap-nuc     ← download nix-user-chroot binary (step 0)
│   └── bootstrap-home    ← re-create real-home dotfiles after a wipe
└── bootstrap/
    └── nix-user-chroot   ← the nix-user-chroot binary itself
```

---

## Prerequisites

Check that unprivileged user namespaces are enabled on the cluster:

```bash
unshare --user --pid echo YES
# Must print: YES
# If you get "unshare: unshare failed: Operation not permitted", stop here —
# contact HPC support and ask them to enable user namespaces (kernel param
# kernel.unprivileged_userns_clone=1).
```

You need `curl` and `bash` available in the real login shell (they always are on
any sane cluster).

---

## First-Time Setup

### 0. Seed `$SCR/bin` (chicken-and-egg)

After the first `home-manager switch` these scripts are managed declaratively,
but for the very first time you have to create them by hand **or** just copy the
bootstrap scripts out of the repo once you've cloned it. The easiest path is:

```bash
SCR=/scratch.hpc/joaofilipe.silvade
mkdir -p "$SCR/bin" "$SCR/bootstrap"
```

Then paste / copy `modules/hosts/unibo/bin/bootstrap-nuc` there (or just run the
one-liner below directly):

```bash
# Download nix-user-chroot (x86_64-linux)
curl -fsSL \
  https://github.com/nix-community/nix-user-chroot/releases/latest/download/nix-user-chroot-bin-2.1.1-x86_64-unknown-linux-musl \
  -o "$SCR/bootstrap/nix-user-chroot"
chmod +x "$SCR/bootstrap/nix-user-chroot"
```

Verify it works:

```bash
$SCR/bootstrap/nix-user-chroot $SCR/.nix bash -c 'echo "chroot OK"'
```

### 1. Install Nix (single-user, no daemon) inside the chroot

```bash
$SCR/bootstrap/nix-user-chroot "$SCR/.nix" \
  env HOME="$SCR" \
  bash -c 'curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon'
```

The installer writes everything under `/nix` (= `$SCR/.nix`) and drops a profile
at `$SCR/.nix-profile`. It will print `. $SCR/.nix-profile/etc/profile.d/nix.sh`
at the end — **don't** run that yet; it only works inside the chroot.

### 2. Enter the chroot and source Nix

```bash
$SCR/bootstrap/nix-user-chroot "$SCR/.nix" env HOME="$SCR" bash -l
```

You are now inside the chroot. Source Nix:

```bash
. "$SCR/.nix-profile/etc/profile.d/nix.sh"
nix --version   # should print e.g. nix (Nix) 2.x.y
```

### 3. Enable flakes for the bootstrap session

```bash
mkdir -p "$SCR/.config/nix"
cat > "$SCR/.config/nix/nix.conf" << 'EOF'
experimental-features = nix-command flakes pipe-operators
EOF
```

After `home-manager switch` this file is managed by the `standalone-hm` module;
this is just a temporary seed so you can run flake commands now.

### 4. Clone your config repo

```bash
# Inside the chroot
git clone https://github.com/<you>/.setup "$SCR/.setup"
# — or if you already have it elsewhere:
cp -r /path/to/.setup "$SCR/.setup"
```

### 5. Run home-manager for the first time

```bash
# Inside the chroot, with nix sourced
nix run 'github:nix-community/home-manager' -- \
  switch --flake "$SCR/.setup#unibo" \
  --extra-experimental-features 'nix-command flakes'
```

This will take a while on first run (builds / fetches everything). Subsequent
runs use the `update` alias: `update` → `home-manager switch --flake $SCR/.setup#unibo`.

### 6. Set up the real-home dotfiles

The cluster will wipe your real `$HOME`; tell it to forward to `$SCR` on every
login. Run this **outside** the chroot (exit it first, or open a second terminal):

```bash
$SCR/bin/bootstrap-home
```

This creates `~/.bashrc` (sources `$SCR/.bashrc`) and `~/.bash_profile` (executes
`nix-enter` automatically on interactive login).

### 7. Re-login

Log out and back in. You should automatically land inside the chroot with your full home-manager environment. Confirm:

```bash
echo $HOME     # /scratch.hpc/joaofilipe.silvade
nix --version  # works
tmux           # works
```

---

## After a Home-Directory Wipe

The cluster admins wiped `~`. You log in to a bare shell. Do:

```bash
# 1. Re-create real-home dotfiles (nix-user-chroot binary is still in $SCR)
/scratch.hpc/joaofilipe.silvade/bin/bootstrap-home

# 2. Re-login (or just exec manually)
exec /scratch.hpc/joaofilipe.silvade/bin/nix-enter
```

That's it. Everything else (Nix store, home-manager profile, your configs) is
still intact in `$SCR`.

If for some reason the `bin/` scripts themselves were lost (e.g. `$SCR` was also
wiped — unlikely but possible), go back to **Step 0** above.

---

## Daily Workflow

```
ssh giano                     # auto-executes nix-enter via .bash_profile
  └─ chroot shell, HOME=$SCR
       ├─ update              # alias: home-manager switch --flake $SCR/.setup#unibo
       ├─ tmux / zsh / etc.   # fully managed by home-manager
       └─ nix develop / run   # normal Nix, full /nix/store available
```

---

## CUDA / NVIDIA

CUDA works as on any other machine. `nix-user-chroot` only sets up a
user-namespace mount for `/nix`; it does not sandbox hardware. The host kernel
driver (`nvidia.ko`) and `/dev/nvidia*` devices are visible inside the chroot.

To use CUDA packages from Nixpkgs inside a dev shell:

```nix
# in a flake.nix devShell
packages = with pkgs; [ cudaPackages.cudatoolkit ];
```

If the cluster has `module load cuda/...`, those paths are also visible inside
the chroot (the host `/proc`, `/sys`, `/dev`, and environment are inherited).

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `unshare: Operation not permitted` | User namespaces disabled — ask HPC support |
| `nix-enter` hangs at bind-mount | `$SCR/.nix` may be on a FUSE/NFS mount that doesn't support bind-mounts; try `--no-pivot` flag (see nix-user-chroot docs) |
| Nix store corruption after node crash | Run `nix-store --verify --repair` inside the chroot |
| `home-manager switch` fails on first run | Make sure `$SCR/.config/nix/nix.conf` has `experimental-features = nix-command flakes` (Step 3) |
| `update` alias not found | You're outside the chroot; run `nix-enter` first |
| `git` not available for clone in Step 4 | `nix shell nixpkgs#git --extra-experimental-features 'nix-command flakes'` |
