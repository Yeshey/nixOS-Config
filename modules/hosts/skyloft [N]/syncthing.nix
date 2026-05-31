{
  flake.modules.nixos.skyloft = {
  };

  flake.modules.homeManager.skyloft = {
    services.syncthing = {
      guiAddress = "0.0.0.0:8384";
    };
  };

  flake.modules.nixos.skyloft = {
    services.syncthing = {
      guiAddress = "0.0.0.0:8384";
    };
  };
}