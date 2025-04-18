{ pkgs, ... }:

{
    forgeServers = pkgs.callPackage ./forge-servers/default.nix {};
}
