{
  inputs,
  ...
}:
{
  # default settings needed for all homeManagerConfigurations

  flake.modules.homeManager.system-minimal =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.homeDirectory =
        if pkgs.stdenv.isDarwin then
          (lib.mkForce "/Users/${config.home.username}")
        else
          lib.mkDefault "/home/${config.home.username}";
      home.stateVersion = lib.mkDefault "25.11";
    };
}
