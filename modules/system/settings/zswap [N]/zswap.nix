{ inputs, ... }:
{
  flake.modules.nixos.zswap =
    { ... }:
    {
      imports = [
        # zswap module merged Apr 10 2026, remove when nixpkgs stable includes it
        "${inputs.nixpkgs-unstable}/nixos/modules/system/boot/zswap.nix"
      ];

      zramSwap.enable = false;

      boot.zswap.enable = true;
    };
}