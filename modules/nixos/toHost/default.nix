{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost;
in
{
  imports = [
    ./dontStarveTogetherServer.nix
    ./nextcloud.nix # TODO not working right boy nixos-rebuild build-vm --flake ~/.setup#skyloft not working
    ./openvscodeServer.nix # vscoduium is not well
    ./ngixServer
    ./kubo.nix
    ./mindustry-server.nix
    ./freeGames.nix
    ./remoteWorkstation/default.nix
    ./searx.nix
    ./ollama.nix
    ./openhands.nix
    ./overleaf.nix
  ];

  options.toHost = with lib; {

  };

  config = lib.mkIf cfg.enable {

  };
}
