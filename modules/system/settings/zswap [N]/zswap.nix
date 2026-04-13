{ inputs, ... }:
{
  flake.modules.nixos.zswap =
    { lib, ... }:
    {
      imports = [
        # TODO zswap module merged Apr 10 2026, remove when nixpkgs stable includes it, along with the flake-parts file
        "${inputs.nixpkgs-zswap}/nixos/modules/system/boot/zswap.nix"
      ];

      zramSwap.enable = false;

      boot.zswap = {
        enable = true;
        maxPoolPercent = lib.mkDefault 35;
      };
    };
}