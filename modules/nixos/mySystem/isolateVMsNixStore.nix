{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.isolateVMsNixStore;
in
{
  options.mySystem = {
    isolateVMsNixStore = lib.mkEnableOption "isolateVMsNixStore";
  };

  config = lib.mkIf (config.mySystem.enable && cfg)  {
    # force virtual machines to have their own store seperate from the host. Good to try dangerous commands, spin up a machine with something:
    # nixos-rebuild build-vm --flake .#twilightrealm
    virtualisation.mountHostNixStore = false;
    virtualisation.useNixStoreImage = true;
    virtualisation.useBootLoader = true;
  };
}
