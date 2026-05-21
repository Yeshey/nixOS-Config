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
        "home-manager switch --flake path:${scr}/.setup#unibo --impure";

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
                bash -c '
                  export PATH="${scr}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
                  source "${scr}/.nix-profile/etc/profile.d/nix.sh" 2>/dev/null || true
                  source "${scr}/.nix-profile/etc/profile.d/hm-session-vars.sh" 2>/dev/null || true
                  exec "${scr}/.nix-profile/bin/zsh" -l
                '
            '';
          };

          bashrc = pkgs.writeText "scr-bashrc" ''
            # enter nix-user-chroot automatically if not already inside
            if [[ -z "''${_NIX_CHROOT:-}" ]] && [[ -x "${scr}/bin/nix-enter" ]]; then
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