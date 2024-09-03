trap "cd '${cfg.falkeLocation}' && git checkout -- flake.lock" INT # if interrupted

# Ask for password upfront
# sudo -v

nix flake update "${cfg.falkeLocation}"

if nixos-rebuild switch --flake "${cfg.falkeLocation}#${config.mySystem.host}"; then
    echo "NixOS upgrade successful."
else
    echo "Unable to update all flake inputs, trying to update just nixpkgs"
    cd "${cfg.falkeLocation}" && git checkout -- flake.lock
    if nixos-rebuild switch --flake "${cfg.falkeLocation}#${config.mySystem.host}" \
        --update-input nixpkgs; then
        echo "NixOS upgrade with nixpkgs update successful."
    else
        echo "NixOS upgrade failed. Rolling back changes to flake.lock"
        cd "${cfg.falkeLocation}" && git checkout -- flake.lock
    fi
fi