{ inputs, ... }:
{
  # Run x86_64 (and i386 via Box32) binaries on aarch64 NixOS via box64.
  # https://github.com/Yeshey/nixos-box64-binfmt

  flake-file.inputs = {
    box64-binfmt.url = "github:Yeshey/nixos-box64-binfmt";
    # box64-binfmt.path = "/home/yeshey/PersonalFiles/2025/Projects/box64-binfmt/";
    box64-binfmt.inputs.nixpkgs.follows = "nixpkgs";
    # box64-binfmt = {
    #   type = "path";
    #   path = "/home/yeshey/PersonalFiles/2025/Projects/box64-binfmt/";
    # };
  };

  imports = [ inputs.box64-binfmt.flakeModules.default ];
}