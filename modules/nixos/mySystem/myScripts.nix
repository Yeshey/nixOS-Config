{
  config,
  lib,
  pkgs,
  ...
}:
let 
  cfg = config.mySystem;
in 
let
      upgrade = pkgs.writeShellScriptBin "upgrade"
''
trap "cd '${cfg.zsh.falkeLocation}' && git checkout -- flake.lock" INT # if interrupted

# Ask for password upfront
# sudo -v

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo. Please run it again as: sudo $0"
   exit 1
fi

nix flake update --flake "${cfg.zsh.falkeLocation}"

if nixos-rebuild switch --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}"; then
    echo "NixOS upgrade successful."
else
    echo "Unable to update all flake inputs, trying to update just nixpkgs"
    cd "${cfg.zsh.falkeLocation}" && git checkout -- flake.lock
    if nixos-rebuild switch --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}" \
        --update-input nixpkgs; then
        echo "NixOS upgrade with nixpkgs update successful."
    else
        echo "NixOS upgrade failed. Rolling back changes to flake.lock"
        cd "${cfg.zsh.falkeLocation}" && git checkout -- flake.lock
    fi
fi
'';
    upgrade-with-remote-off = pkgs.writeShellScriptBin "upgrade-with-remote-off" ''
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo. Please run it again as: sudo $0"
   exit 1
fi

echo "This will upgrade the local system with the remote computer with the given IP and then power off both the remote and local machines. \n Run with Example: 'sudo upgrade-with-remote-off user@192.168.1.109"

if [ -z "$1" ]; then
    echo "No remote address given! Please provide a user@ip address."
else
    REMOTE_ADDR=$1

    # Split user@ip if provided
    if [[ "$REMOTE_ADDR" == *"@"* ]]; then
        REMOTE_USER=''${REMOTE_ADDR%%@*}
        REMOTE_IP=''${REMOTE_ADDR##*@}
    else
        REMOTE_USER="root"
        REMOTE_IP="$REMOTE_ADDR"
    fi

    trap "cd '${cfg.zsh.falkeLocation}' && git checkout -- flake.lock" INT # if interrupted

    nix flake update --flake "${cfg.zsh.falkeLocation}"

    if nixos-rebuild boot --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}" \
        --build-host "$REMOTE_USER@$REMOTE_IP" \
        --verbose \
        --option eval-cache false; then
        
        echo "NixOS upgrade successful."

        # Power off the remote machine
        ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_IP" "sudo poweroff" && \
            echo "Remote machine ($REMOTE_ADDR) powered off."

        # Power off the local machine
        poweroff && echo "Local machine powered off."
    else
        echo "Unable to update all flake inputs, trying to update just nixpkgs"
        cd "${cfg.zsh.falkeLocation}" && git checkout -- flake.lock
        if nixos-rebuild boot --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}" \
            --build-host "$REMOTE_USER@$REMOTE_IP" \
            --verbose \
            --option eval-cache false \
            --update-input nixpkgs; then
            
            echo "NixOS upgrade with nixpkgs update successful."

            # Power off the remote machine
            ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_IP" "sudo poweroff" && \
                echo "Remote machine ($REMOTE_ADDR) powered off."

            # Power off the local machine
            poweroff && echo "Local machine powered off."
        else
            echo "NixOS upgrade failed. Rolling back changes to flake.lock"
            cd "${cfg.zsh.falkeLocation}" && git checkout -- flake.lock
        fi
    fi
fi
'';
update-with-remote-off = pkgs.writeShellScriptBin "update-with-remote-off" ''
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "This will update the local system with the remote computer and then power off both machines."
echo "Usage: sudo update-with-remote-off user@192.168.1.109"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo. Please run it again as: sudo $0"
   exit 1
fi

if [ -z "$1" ]; then
    echo "No remote address given! Please provide a user@ip address."
else
    REMOTE_ADDR=$1

    # Split user@ip if provided
    if [[ "$REMOTE_ADDR" == *"@"* ]]; then
        REMOTE_USER=''${REMOTE_ADDR%%@*}
        REMOTE_IP=''${REMOTE_ADDR##*@}
    else
        REMOTE_USER="root"
        REMOTE_IP="$REMOTE_ADDR"
    fi

    if nixos-rebuild boot --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}" \
        --build-host "$REMOTE_USER@$REMOTE_IP" \
        --verbose \
        --option eval-cache false; then
        
        echo "NixOS update successful."

        # Power off the remote machine using sudo
        ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_IP" "sudo poweroff" && \
            echo "Remote machine ($REMOTE_ADDR) powered off."

        # Power off the local machine
        poweroff && echo "Local machine powered off."
    else
        echo "NixOS update failed."
    fi
fi
'';
  clean = pkgs.writeShellScriptBin "clean"
''
# Script to clean all generations and optimize the Nix store

echo "This will clean all generations and optimise the store, uninstall unused Flatpak packages and remove dangling docker images, volumes and networks"

# Run the Nix garbage collection and store optimization commands as root
sudo sh -c '
    # Remove old Nix generations
    nix-collect-garbage -d
    
    # Optimize the Nix store
    nix-store --optimise
    
    # Run garbage collection again to remove unused items
    nix-store --gc
    
    # Display any stray roots, filtering out specific directories
    echo "Displaying stray roots:"
    nix-store --gc --print-roots | egrep -v "^(/nix/var|/run/current-system|/run/booted-system|/proc|\{memory|\{censored)"
    
    # Uninstall unused Flatpak packages
    flatpak uninstall --unused -y

    echo "sudo Removing dangling docker and podman images, volumes and networks"
    ${pkgs.docker}/bin/docker system prune --volumes --force
    ${pkgs.podman}/bin/podman system prune -a -f
'

# Collect garbage again for cleanup
nix-collect-garbage -d

echo "Removing dangling docker and podman images, volumes and networks"
${pkgs.docker}/bin/docker system prune --volumes --force
${pkgs.podman}/bin/podman system prune -a -f

# Provide user guidance on the next steps
echo "You should do a nixos-rebuild boot and a reboot to clean the boot generations now."
'';
  cleangit = pkgs.writeShellScriptBin "cleangit"
''
    find . -type d \( -name '.stversions' -prune \) -o \( -name '.git' -type d -execdir sh -c 'echo "Cleaning repository in $(pwd)"; git clean -fdx' \; \)
'';
  cleansyncthing = pkgs.writeShellScriptBin "cleansyncthing"
''
    echo "Deleting sync conflict files in: $(pwd)"
    find . -mount -mindepth 1 -type f \
        -not \( -path "*/.Trash-1000/*" -or -path "*.local/share/Trash/*" \) \
        -name "*.sync-conflict-*" -ls -delete
'';
in
{
  options.mySystem.myScripts = with lib; {
    # enable = mkEnableOption "myScripts";
  };

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = { 

    ### MY SCRIPTS ###
    environment.systemPackages = with pkgs; [
      upgrade
      upgrade-with-remote-off
      update-with-remote-off
      clean
      cleangit
      cleansyncthing
    ];

  };
}
