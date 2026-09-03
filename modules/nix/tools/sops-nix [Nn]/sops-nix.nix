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

        # This tells sops-nix to use your server's native SSH host key to decrypt the secrets!
        # This means you don't have to provision a specific age key manually.
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        
        # (Optional) If your server doesn't have an SSH key yet, setting this to true 
        # will generate one automatically during activation.
        age.generateKey = true;
      };
    };
}