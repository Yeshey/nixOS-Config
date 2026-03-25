{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.virtualbox;
in
{
  options.mySystem.virtualbox = with lib; {
    enable = mkEnableOption "virtualbox";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) { 

    virtualisation.virtualbox.host.enable = true;
    
    virtualisation.virtualbox.host.enableExtensionPack = true;
    
    users.users.yeshey.extraGroups = [ "vboxusers" ];
    
    environment.systemPackages = with pkgs; [
      vagrant
    ];

    # might need
    # boot.blacklistedKernelModules = [ "kvm" "kvm_intel" ];  # or "kvm_amd"

  };
}
