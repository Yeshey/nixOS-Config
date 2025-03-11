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
    ./minecraft.nix
    ./openvscodeServer.nix # vscoduium is not well
    ./ngixServer
    ./mineclone.nix
    ./kubo.nix
    ./mindustry-server.nix
    ./freeGames.nix
    ./remoteWorkstation/default.nix
    ./learnWithT.nix
    ./searx.nix
  ];

  options.toHost = with lib; {

  };

  config = lib.mkIf cfg.enable {

  };
}
