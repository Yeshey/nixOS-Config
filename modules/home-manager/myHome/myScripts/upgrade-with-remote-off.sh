export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

echo "This will upgrade the local system with the remote computer with the given IP and then power off both the remote and local machines. \n Run with Example: 'upgrade-with-remote-off 192.168.1.109'"

if [ -z "$1" ]; then
    echo "No IP given! Please provide an IP address."
else
    REMOTE_IP=$1

    trap "cd '${cfg.falkeLocation}' && git checkout -- flake.lock" INT # if interrupted

    # Ask for password upfront
    # sudo -v

    nix flake update "${cfg.falkeLocation}"

    if nixos-rebuild boot --flake "${cfg.falkeLocation}#${config.mySystem.host}" --build-host root@"''${REMOTE_IP}" --verbose --option eval-cache false; then
        echo "NixOS upgrade successful."

        # Power off the remote machine
        ssh -o StrictHostKeyChecking=no root@"''${REMOTE_IP}" "sudo poweroff" && echo "Remote machine powered off."

        # Power off the local machine
        poweroff && echo "Local machine powered off."
    else
        echo "Unable to update all flake inputs, trying to update just nixpkgs"
        cd "${cfg.falkeLocation}" && git checkout -- flake.lock
        if nixos-rebuild boot --flake "${cfg.falkeLocation}#${config.mySystem.host}" --build-host root@"''${REMOTE_IP}" --verbose --option eval-cache false --update-input nixpkgs; then
            echo "NixOS upgrade with nixpkgs update successful."

            # Power off the remote machine
            ssh  -o StrictHostKeyChecking=noroot@"''${REMOTE_IP}" "sudo poweroff" && echo "Remote machine powered off."

            # Power off the local machine
            poweroff && echo "Local machine powered off."
        else
            echo "NixOS upgrade failed. Rolling back changes to flake.lock"
            cd "${cfg.falkeLocation}" && git checkout -- flake.lock
        fi
    fi
fi