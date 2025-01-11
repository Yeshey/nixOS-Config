{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem = with lib; {
    vmHost = mkOption {
      type = types.bool;
      default = false;
    };
    dockerHost = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.mySystem.enable && config.mySystem.vmHost) {
      users.users.${config.mySystem.user}.extraGroups = [ "libvirtd" ];
      virtualisation.libvirtd.enable = true;
      virtualisation.spiceUSBRedirection.enable = true; # to enable USB rederection in virt-manager (https://github.com/NixOS/nixpkgs/issues/106594)
      environment.systemPackages = with pkgs; [
        virt-manager # virtual machines
        virt-viewer # needed to choose share folders with windows VM (guide and video: https://www.guyrutenberg.com/2018/10/25/sharing-a-folder-a-windows-guest-under-virt-manager/ and https://www.youtube.com/watch?v=Ow3gVbkWj-c)
        spice-gtk # for virtual machines (to connect usbs and everything else)
      ];
    })
    (lib.mkIf (config.mySystem.enable && config.mySystem.dockerHost) {
      users.users.${config.mySystem.user}.extraGroups = [ "docker" ];
      virtualisation.docker = {
        enable = true;
      };
      virtualisation.podman = {
        enable = true;
      };
    })
  ];
}
