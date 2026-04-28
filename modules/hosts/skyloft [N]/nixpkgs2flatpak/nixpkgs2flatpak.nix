{ inputs, ... }:
{
  flake.modules.nixos.skyloft =
    { config, ... }:
    {
      imports = [
        inputs.nixpkgs2flatpak.nixosModules.flatpakServer
      ];

      services.nixpkgs2flatpak = {
        enable = true;
        domain = "10.8.0.1";           
        enableSSL = false;             
        # Point directly to your OneDrive mount!
        repoPath = "/mnt/OneDrive/ISCTE/nixpkgs2flatpak";
      };

      # Extra security fix: Ensure Nginx has permission to traverse the mount
      # rclone mounts often need the parent directories to be executable (+x)
      systemd.tmpfiles.rules = [
        "d /mnt/OneDrive/ISCTE 0755 root root -"
      ];
    };
}