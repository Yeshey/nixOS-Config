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
    ./codeserver.nix
    ./nginxServer
    ./kubo.nix
    ./mindustry-server.nix
    ./freeGames.nix
    ./remoteWorkstation/default.nix
    ./searx.nix
    ./ollama.nix
    ./openhands.nix
    ./overleaf.nix
    ./minecraft/default.nix
    ./luanti.nix
    ./wireguardVPN.nix
    ./openVPN.nix
    ./vnstat.nix
  ];

  options.toHost = with lib; {

  };

  config = lib.mkIf cfg.enable {

  };
}
