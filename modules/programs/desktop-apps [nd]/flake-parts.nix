{ ... }:
{
  # Auto-updating Antigravity packages (nixpkgs lags upstream)
  # https://github.com/jacopone/antigravity-nix
  flake-file.inputs.antigravity-nix = {
    url = "github:jacopone/antigravity-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}