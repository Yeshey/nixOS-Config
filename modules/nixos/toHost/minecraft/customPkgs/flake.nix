{
  description = "Custom Packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux = {
      forgeServers = nixpkgs.callPackage ./forge-servers/default.nix {};
    };
  };
}