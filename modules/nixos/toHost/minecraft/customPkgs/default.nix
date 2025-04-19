# this forge-servers config from https://github.com/Stefanuk12/nixos-config/blob/main/system/vps/minecraft/servers/fearNightfall/default.nix
{ pkgs, ... }:

{
    forgeServers = pkgs.callPackage ./forge-servers/default.nix {};
}
