{
  flake.modules.nixos.virt =
    { pkgs, ... }:
    {
      virtualisation.libvirtd.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
      programs.virt-manager.enable = true;
      environment.systemPackages = with pkgs; [
        virt-viewer
        spice-gtk
      ];
    };
}