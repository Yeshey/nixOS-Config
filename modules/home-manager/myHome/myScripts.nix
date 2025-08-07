{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome;
in
let 
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

${pkgs.nh}/bin/nh clean all

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
  options.myHome.myScripts = with lib; {
    #enable = mkEnableOption "myScripts";
  };
  # always active
  config = {

    home.packages = with pkgs; [
      clean
      cleangit
      cleansyncthing
    ];

  };
}
