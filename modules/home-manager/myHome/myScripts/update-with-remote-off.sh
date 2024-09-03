export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

echo "This will update the local system with the remote computer with the given IP and then power off both the remote and local machines. \n Run with Example: 'update-with-remote-off 192.168.1.109'"

if [ -z "$1" ]; then
    echo "No IP given! Please provide an IP address."
else
    REMOTE_IP=$1

    # Ask for password upfront
    # sudo -v

    if nixos-rebuild boot --flake "${cfg.falkeLocation}#${config.mySystem.host}" --build-host root@"''${REMOTE_IP}" --verbose --option eval-cache false; then
        echo "NixOS update successful."

        # Power off the remote machine
        ssh -o StrictHostKeyChecking=no root@"''${REMOTE_IP}" "sudo poweroff" && echo "Remote machine powered off."

        # Power off the local machine
        poweroff && echo "Local machine powered off."
    else
        echo "NixOS update failed."
    fi
fi