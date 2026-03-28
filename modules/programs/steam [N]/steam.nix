{
  flake.modules.nixos.steam =
    {
      programs.steam = {
        enable               = true;
        remotePlay.openFirewall = true;
      };
      programs.gamemode.enable = true;
      services.joycond.enable = true;
    };
}