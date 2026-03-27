{
  flake.modules.nixos.waydroid = 
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages =  [ 
        pkgs.waydroid-helper 
        # wl-clipboard # to make clipboard work # TODO
      ];
      systemd = {
        packages = [ pkgs.waydroid-helper ];
        services.waydroid-mount.wantedBy = [ "multi-user.target" ];
      };
      virtualisation.waydroid.enable = true;
    };
}
