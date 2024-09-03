{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem;
in
{
  options.mySystem.safe-rm = with lib; {
    # enable = mkEnableOption "safe-rm";
  };

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = { 


    ### MY SCRIPTS ###
    environment.systemPackages = let 
      upgarde-new = pkgs.writeShellScriptBin "upgarde-new" (builtins.toFile "upgrade.sh"
''
trap "cd '${cfg.zsh.falkeLocation}' && git checkout -- flake.lock" INT # if interrupted

# Ask for password upfront
# sudo -v

nix flake update "${cfg.zsh.falkeLocation}"

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
''
      );
      upgrade-with-remote-off-new = pkgs.writeShellScriptBin "upgrade-with-remote-off-new" (builtins.toFile "upgrade-with-remote-off.sh"
''
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

echo "This will upgrade the local system with the remote computer with the given IP and then power off both the remote and local machines. \n Run with Example: 'upgrade-with-remote-off 192.168.1.109'"

if [ -z "$1" ]; then
    echo "No IP given! Please provide an IP address."
else
    REMOTE_IP=$1

    trap "cd '${cfg.zsh.falkeLocation}' && git checkout -- flake.lock" INT # if interrupted

    # Ask for password upfront
    # sudo -v

    nix flake update "${cfg.zsh.falkeLocation}"

    if nixos-rebuild boot --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}" --build-host root@"''${REMOTE_IP}" --verbose --option eval-cache false; then
        echo "NixOS upgrade successful."

        # Power off the remote machine
        ssh -o StrictHostKeyChecking=no root@"''${REMOTE_IP}" "sudo poweroff" && echo "Remote machine powered off."

        # Power off the local machine
        poweroff && echo "Local machine powered off."
    else
        echo "Unable to update all flake inputs, trying to update just nixpkgs"
        cd "${cfg.zsh.falkeLocation}" && git checkout -- flake.lock
        if nixos-rebuild boot --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}" --build-host root@"''${REMOTE_IP}" --verbose --option eval-cache false --update-input nixpkgs; then
            echo "NixOS upgrade with nixpkgs update successful."

            # Power off the remote machine
            ssh  -o StrictHostKeyChecking=noroot@"''${REMOTE_IP}" "sudo poweroff" && echo "Remote machine powered off."

            # Power off the local machine
            poweroff && echo "Local machine powered off."
        else
            echo "NixOS upgrade failed. Rolling back changes to flake.lock"
            cd "${cfg.zsh.falkeLocation}" && git checkout -- flake.lock
        fi
    fi
fi
''
      );
      update-with-remote-off-new = pkgs.writeShellScriptBin "update-with-remote-off-new" (builtins.toFile "update-with-remote-off.sh"
''
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

echo "This will update the local system with the remote computer with the given IP and then power off both the remote and local machines. \n Run with Example: 'update-with-remote-off 192.168.1.109'"

if [ -z "$1" ]; then
    echo "No IP given! Please provide an IP address."
else
    REMOTE_IP=$1

    # Ask for password upfront
    # sudo -v

    if nixos-rebuild boot --flake "${cfg.zsh.falkeLocation}#${config.mySystem.host}" --build-host root@"''${REMOTE_IP}" --verbose --option eval-cache false; then
        echo "NixOS update successful."

        # Power off the remote machine
        ssh -o StrictHostKeyChecking=no root@"''${REMOTE_IP}" "sudo poweroff" && echo "Remote machine powered off."

        # Power off the local machine
        poweroff && echo "Local machine powered off."
    else
        echo "NixOS update failed."
    fi
fi
''
      );
    in with pkgs; [
      upgarde-new
      upgrade-with-remote-off-new
      update-with-remote-off-new
    ];

  };
}
