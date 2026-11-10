{
  # Unmerged PR #6 (Yunor743/strata.nix), pinned to its commit.
  # No nixpkgs follows: the HIP build needs a hipBLASLt tuning table matching its ROCm version.
  flake-file.inputs.strata-nix.url = "github:rake5k/strata.nix/893f924e83e789e5f81e3f3f1407da3186b98ee4";
}