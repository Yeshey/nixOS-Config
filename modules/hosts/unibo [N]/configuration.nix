{ inputs, lib, pkgs, ... }:
let
  username = "joaofilipe.silvade";
  scr      = "/scratch.hpc/${username}";
in
{
  flake.modules.homeManager.unibo =
    { pkgs, config, lib, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        standalone-hm
        tmux shell ssh starship direnv
        nix-index-database nix-your-shell
        zed-editor-host
        system-minimal
      ];

      home.username      = username;
      home.homeDirectory = lib.mkForce scr;
      home.stateVersion  = "25.11";

      nixpkgs.overlays = [
        (final: prev: {
          local.coreutils-with-safe-rm =
            prev.callPackage "${inputs.packages}/coreutils-with-safe-rm" {};
        })
      ];

      programs.zsh.shellAliases.update = lib.mkForce
        "echo 'If you run out of ram building, request a machine with srun --pty --mem=8G -c 2 /bin/bash' && ${scr}/bin/nix-enter -- home-manager switch -b backup --flake path:${scr}/.setup#unibo --impure";

      programs.zsh.initContent = lib.mkBefore ''
        echo "All your files should be in ${scr}/"
      '';

      programs.bash.initExtra = lib.mkBefore ''
        echo "All your files should be in ${scr}/"
      '';

      nix.extraOptions = lib.mkForce ''
        !include ./extra.conf
        experimental-features = nix-command flakes pipe-operators
      '';

      home.sessionPath = [ "${scr}/bin" ];

      # Write bootstrap files as REAL copies (not nix store symlinks).
      # home.file creates symlinks into /nix/store which are dead outside
      # the nix-user-chroot — these files must survive outside it.
      home.activation.writeBootstrapFiles =
        let
          nixEnter = pkgs.writeTextFile {
            name = "nix-enter";
            executable = true;
            text = ''
              #!/usr/bin/env bash
              set -euo pipefail
              NUC="${scr}/bootstrap/nix-user-chroot"
              ROOT_DIR="${scr}/nix-root"
              [[ -x "$NUC" ]] || { printf 'ERROR: %s not found\n' "$NUC" >&2; exit 1; }

              exec "$NUC" "$ROOT_DIR" env \
                _NIX_CHROOT=1 \
                HOME="${scr}" \
                USER="${username}" \
                XDG_STATE_HOME="${scr}/.local/state" \
                XDG_CONFIG_HOME="${scr}/.config" \
                XDG_DATA_HOME="${scr}/.local/share" \
                bash -lc '
                  export PATH="${scr}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
                  source "${scr}/.nix-profile/etc/profile.d/nix.sh" 2>/dev/null || true
                  source "${scr}/.nix-profile/etc/profile.d/hm-session-vars.sh" 2>/dev/null || true

                  if [ "$#" -eq 0 ]; then
                    exec "${scr}/.nix-profile/bin/zsh" -l
                  else
                    exec "$@"
                  fi
                ' nix-enter "$@"
            '';
          };

          bashrc = pkgs.writeText "scr-bashrc" ''
            if [[ -z "''${_NIX_CHROOT:-}" ]] && [[ -n "$SSH_TTY" ]] && [[ -x "${scr}/bin/nix-enter" ]]; then
              exec "${scr}/bin/nix-enter"
            fi
          '';

          bootstrapNuc = pkgs.writeTextFile {
            name = "bootstrap-nuc";
            executable = true;
            text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            DEST="${scr}/bootstrap/nix-user-chroot"
            mkdir -p "${scr}/bootstrap" "${scr}/nix-root"
            printf 'Downloading nix-user-chroot…\n'
            curl -fsSL \
              "https://github.com/nix-community/nix-user-chroot/releases/latest/download/nix-user-chroot-x86_64-unknown-linux-musl" \
              -o "$DEST"
            chmod +x "$DEST"
            printf 'Done → %s\n' "$DEST"
            printf 'Now run:\n  %s %s/nix-root bash -c "curl -L https://nixos.org/nix/install | bash -s -- --no-daemon"\n' "$DEST" "${scr}"
          '';
          };

            bootstrapHome = pkgs.writeTextFile {
              name = "bootstrap-home";
              executable = true;
              text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            REAL_HOME=$(getent passwd "$USER" | cut -d: -f6)
            printf '[ -f "${scr}/.bashrc" ] && . "${scr}/.bashrc"\n' \
              > "$REAL_HOME/.bashrc"
            printf 'Real ~/.bashrc now sources %s/.bashrc\n' "${scr}"
          '';
          };
        in
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          mkdir -p "${scr}/bin"
          install -m755 ${nixEnter}      "${scr}/bin/nix-enter"
          install -m755 ${bootstrapNuc}  "${scr}/bin/bootstrap-nuc"
          install -m755 ${bootstrapHome} "${scr}/bin/bootstrap-home"
          install -m644 ${bashrc}        "${scr}/.bashrc"
        '';
    };
}
