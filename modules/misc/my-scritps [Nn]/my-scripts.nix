let
  mkCleanSyncthing = pkgs: pkgs.writeShellScriptBin "cleansyncthing" ''
    echo "Deleting Syncthing conflict files in: $(pwd)"
    find . -mount -mindepth 1 -type f \
        -not \( -path "*/.Trash-1000/*" -or -path "*.local/share/Trash/*" \) \
        -name "*.sync-conflict-*" -ls -delete
  '';

  mkCleanGit = pkgs: pkgs.writeShellScriptBin "cleangit" ''
    find . -type d -name '.git' -execdir sh -c \
      'echo "Cleaning repository in $(pwd)"; git clean -fdx' \;
  '';

  combfiles = pkgs: pkgs.writeShellScriptBin "combfiles" (builtins.readFile ./combfiles.sh);

  portableScripts = pkgs: [ (mkCleanSyncthing pkgs) (mkCleanGit pkgs) (combfiles pkgs) ];
in
{
  flake.modules.nixos.my-scripts =
    { pkgs, lib, config, ... }:
    let
      cfg = config.my-scripts;

      # Extract variables for readability in the scripts
      flakeLoc = cfg.flakeLocation;
      hostName = cfg.hostName;

      upgrade = pkgs.writeShellScriptBin "upgrade" ''
        # Trap to rollback flake.lock if the update is interrupted
        trap "cd '${flakeLoc}' && git checkout -- flake.lock" INT

        if [[ $EUID -ne 0 ]]; then
          echo "This script must be run with sudo. Please run it again as: sudo $0"
          exit 1
        fi

        echo "Updating flake at ${flakeLoc}..."
        nix flake update --flake "${flakeLoc}"

        if nixos-rebuild switch --flake "${flakeLoc}#${hostName}"; then
            echo "NixOS upgrade successful."
        else
            echo "Upgrade failed, attempting to update ONLY nixpkgs..."
            cd "${flakeLoc}" && git checkout -- flake.lock
            if nixos-rebuild switch --flake "${flakeLoc}#${hostName}" --update-input nixpkgs; then
                echo "NixOS upgrade with nixpkgs update successful."
            else
                echo "NixOS upgrade failed. Rolling back changes to flake.lock"
                cd "${flakeLoc}" && git checkout -- flake.lock
                exit 1
            fi
        fi
      '';

      update-with-remote-off = pkgs.writeShellScriptBin "update-with-remote-off" ''
        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

        if [[ $EUID -ne 0 ]]; then
          echo "This script must be run with sudo."
          exit 1
        fi

        if [ -z "$1" ]; then
            echo "Usage: sudo update-with-remote-off user@ip"
            exit 1
        fi

        REMOTE_ADDR=$1
        if [[ "$REMOTE_ADDR" == *"@"* ]]; then
            REMOTE_USER=''${REMOTE_ADDR%%@*}
            REMOTE_IP=''${REMOTE_ADDR##*@}
        else
            REMOTE_USER="root"
            REMOTE_IP="$REMOTE_ADDR"
        fi

        if nixos-rebuild boot --flake "${flakeLoc}#${hostName}" \
            --build-host "$REMOTE_USER@$REMOTE_IP" \
            --verbose \
            --option eval-cache false; then
            
            echo "NixOS update successful. Shutting down..."
            ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_IP" "sudo poweroff"
            poweroff
        else
            echo "Update failed. Shutdown aborted."
            exit 1
        fi
      '';

      update-with-remote = pkgs.writeShellScriptBin "update-with-remote" ''
        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

        if [[ $EUID -ne 0 ]]; then
          echo "This script must be run with sudo."
          exit 1
        fi

        if [ -z "$1" ]; then
            echo "Usage: sudo update-with-remote user@ip"
            exit 1
        fi

        REMOTE_ADDR=$1
        if [[ "$REMOTE_ADDR" == *"@"* ]]; then
            REMOTE_USER=''${REMOTE_ADDR%%@*}
            REMOTE_IP=''${REMOTE_ADDR##*@}
        else
            REMOTE_USER="root"
            REMOTE_IP="$REMOTE_ADDR"
        fi

        nixos-rebuild boot --flake "${flakeLoc}#${hostName}" \
            --build-host "$REMOTE_USER@$REMOTE_IP" \
            --verbose \
            --option eval-cache false
      '';

      clean = pkgs.writeShellScriptBin "clean" ''
        echo "Cleaning Nix generations, Docker, Podman, and Flatpaks..."

        sudo sh -c '
            nix-collect-garbage -d
            nix-store --optimise
            nix-store --gc
            echo "Stray roots:"
            nix-store --gc --print-roots | egrep -v "^(/nix/var|/run/current-system|/run/booted-system|/proc|\{memory|\{censored)"
            
            if command -v flatpak &> /dev/null; then
              flatpak uninstall --unused -y
            fi

            if command -v docker &> /dev/null; then
              ${pkgs.docker}/bin/docker system prune --volumes --force
            fi

            if command -v podman &> /dev/null; then
              ${pkgs.podman}/bin/podman system prune -a -f
            fi

            if command -v nh &> /dev/null; then
              ${pkgs.nh}/bin/nh clean all
            fi
        '

        # User-level clean
        nix-collect-garbage -d
        if command -v nh &> /dev/null; then
          ${pkgs.nh}/bin/nh clean all
        fi

        echo "Cleanup complete. Reboot recommended to clear boot entries."
      '';
    in
    {
      options.my-scripts = {
        enable = lib.mkEnableOption "host-level custom scripts";
        
        flakeLocation = lib.mkOption {
          type = lib.types.str;
          default = "/home/yeshey/.setup";
          description = "Path to the NixOS configuration flake.";
        };

        hostName = lib.mkOption {
          type = lib.types.str;
          default = config.networking.hostName;
          description = "The hostname to use when rebuilding the flake.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages =
          (portableScripts pkgs)
          ++ [ upgrade update-with-remote-off update-with-remote clean ];
      };
    };

  flake.modules.homeManager.my-scripts =
    { pkgs, ... }:
    {
      home.packages = portableScripts pkgs;
    };
}