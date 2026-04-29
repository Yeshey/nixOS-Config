{ inputs, ... }:
{
  flake.modules.nixos.skyloft =
    {
      imports = [
        inputs.nixpkgs2flatpak.nixosModules.flatpakServer
      ];

      services.nixpkgs2flatpak = {
        enable = true;
        domain = "143.47.53.175";
        enableSSL = false;
        isDefault = true;
        openFirewall = true;
        repoPath = "/mnt/OneDrive/ISCTE/nixpkgs2flatpak";
      };
    };
}