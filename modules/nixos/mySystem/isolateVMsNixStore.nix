{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  cfg = config.mySystem.isolateVMsNixStore;
in
{
  imports = [
    #<nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
    #(modulesPath + "/installer/scan/not-detected.nix")
    # (modulesPath + "/virtualisation/qemu-vm.nix") # breaks everything wtf 🙂
  ];

  options.mySystem = {
    isolateVMsNixStore = lib.mkEnableOption "isolateVMsNixStore";
  };

  config = lib.mkIf (config.mySystem.enable && cfg)  {
    # force virtual machines to have their own store seperate from the host. Good to try dangerous commands, spin up a machine with something:
    # nixos-rebuild build-vm --flake .#twilightrealm
    # https://discourse.nixos.org/t/building-qemu-kvm-vms/33149/5
    
    # needs to be inside vmVariant? issue: https://github.com/NixOS/nixpkgs/issues/196755
    /*virtualisation = {
      useNixStoreImage = true;
      mountHostNixStore = false;
      useBootLoader = true;
    };*/
    
    virtualisation.vmVariant = {
      useNixStoreImage = true;
      mountHostNixStore = false;
      useBootLoader = true;
    };
    virtualisation.vmVariantWithBootLoader = {
      useNixStoreImage = true;
      mountHostNixStore = false;
      useBootLoader = true;
    };
    
  };
}
