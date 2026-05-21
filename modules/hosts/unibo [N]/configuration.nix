{ inputs, lib, ... }:
let
  username = "joaofilipe.silvade";
  scr      = "/scratch.hpc/${username}";
in
{
  flake.modules.homeManager.unibo =
    { pkgs, config, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        system-cli
        standalone-hm
        zed-editor-host
        tmux
        shell
        ssh
        starship
        direnv
        nix-index-database
        nix-your-shell
      ];

      home.username      = username;
      home.homeDirectory = lib.mkForce scr;

      # standalone-hm hardcodes "#yeshey" — point at this config instead.
      programs.zsh.shellAliases.update = lib.mkForce
        "home-manager switch --flake ${scr}/.setup#unibo --impure";

      # nix-user-chroot bind-mounts $SCR/nix-root as / so the store path is standard /nix/store
      nix.extraOptions = lib.mkForce ''
        !include ./extra.conf
        experimental-features = nix-command flakes pipe-operators
      '';

      home.file.".bashrc".text = ''
        if [[ -z "$_NIX_CHROOT" ]] && [[ -x "${scr}/bin/nix-enter" ]]; then
          exec "${scr}/bin/nix-enter"
        fi
      '';

      home.sessionPath = [ "${scr}/bin" ];

      home.file = {
        # ------------------------------------------------------------------ #
        # nix-enter — primary entry-point for every session                  #
        # ------------------------------------------------------------------ #
        "bin/nix-enter" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            NUC="${scr}/bootstrap/nix-user-chroot"
            ROOT_DIR="${scr}/nix-root"

            if [[ ! -x "$NUC" ]]; then
              printf 'ERROR: nix-user-chroot not found at %s\n' "$NUC" >&2
              exit 1
            fi

            exec "$NUC" "$ROOT_DIR" env \
              _NIX_CHROOT=1 \
              HOME="${scr}" \
              USER="${username}" \
              XDG_STATE_HOME="${scr}/.local/state" \
              XDG_CONFIG_HOME="${scr}/.config" \
              XDG_DATA_HOME="${scr}/.local/share" \
              bash -c '
                export PATH="${scr}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
                source "${scr}/.nix-profile/etc/profile.d/nix.sh" 2>/dev/null || true
                source "${scr}/.nix-profile/etc/profile.d/hm-session-vars.sh" 2>/dev/null || true
                exec "${scr}/.nix-profile/bin/zsh" -l
              '
          '';
        };

        # ------------------------------------------------------------------ #
        # bootstrap-nuc — Step 0 of first-time setup                         #
        # ------------------------------------------------------------------ #
        "bin/bootstrap-nuc" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            DEST="${scr}/bootstrap/nix-user-chroot"
            mkdir -p "${scr}/bootstrap"
            mkdir -p "${scr}/nix-root"

            printf 'Downloading nix-user-chroot (musl) …\n'
            curl -fsSL \
              "https://github.com/nix-community/nix-user-chroot/releases/latest/download/nix-user-chroot-x86_64-unknown-linux-musl" \
              -o "$DEST"
            chmod +x "$DEST"
            
            printf 'OK  →  %s\n' "$DEST"
            printf 'To install nix, run:\n'
            # We use double quotes for the inner command to avoid Nix string escaping issues
            printf '%s %s/nix-root bash -c "curl -L https://nixos.org/nix/install | bash -s -- --no-daemon"\n' "$DEST" "${scr}"
          '';
        };

        # ------------------------------------------------------------------ #
        # bootstrap-home — Link real home to scratch                         #
        # ------------------------------------------------------------------ #
        "bin/bootstrap-home" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            # Get real home path from host system
            REAL_HOME=$(getent passwd "$USER" | cut -d: -f6)
            
            # 1. Update real .bash_profile to auto-enter nix-env
            cat > "$REAL_HOME/.bash_profile" << EOF
            # Auto-enter Nix chroot on interactive login
            if [[ \$- == *i* ]] && [[ -x "${scr}/bin/nix-enter" ]]; then
              exec "${scr}/bin/nix-enter"
            fi
            # Fallback if nix-enter is missing
            [ -f "\$HOME/.bashrc" ] && . "\$HOME/.bashrc"
            EOF

            # 2. Update real .bashrc to point to scratch bashrc
            echo "[ -f \"${scr}/.bashrc\" ] && . \"${scr}/.bashrc\"" > "$REAL_HOME/.bashrc"

            printf 'Host home configured to auto-exec nix-enter.\n'
          '';
        };
      };

      home.stateVersion = "25.11";
    };
}