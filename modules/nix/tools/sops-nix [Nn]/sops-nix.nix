{ inputs, ... }:
{
  flake.modules.nixos.sops-nix =
    { pkgs, config, ... }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      # Install the sops CLI tool so you can edit secrets on the machine if needed
      environment.systemPackages = [ pkgs.sops ];

      sops = {
        # This points to your encrypted secrets file in your repo
        defaultSopsFile = ../../../../secrets/secrets.yaml;
        defaultSopsFormat = "yaml";

        # Use the server's native SSH host key to decrypt secrets at the
        # system level. This means you don't have to provision a specific
        # age key manually for the system.
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

        # Generate the host SSH key during activation if it doesn't exist yet.
        age.generateKey = true;
      };
    };

  flake.modules.homeManager.sops-nix =
    { config, ... }:
    {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops = {
        defaultSopsFile = ../../../../secrets/secrets.yaml;
        defaultSopsFormat = "yaml";

        # Use your user's existing age key. This is the key your VS Code
        # extension uses to edit secrets, so the same recipient already
        # exists in .sops.yaml and the file decrypts cleanly.
        age = {
          keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        };
      };
    };
}