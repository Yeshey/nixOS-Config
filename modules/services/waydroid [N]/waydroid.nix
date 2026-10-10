{
  flake.modules.nixos.waydroid =
    {
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.waydroid-helper
        # wl-clipboard # to make clipboard work # TODO
      ];

      systemd = {
        packages = [ pkgs.waydroid-helper ];

        services.waydroid-mount = {
          wantedBy = lib.mkForce [ ];
          partOf = [ "waydroid-container.service" ];
        };

        # Allow D-Bus activation without starting the container service at boot.
        services.waydroid-container = {
          wantedBy = lib.mkForce [ ];
          wants = [ "waydroid-mount.service" ];
          after = [ "waydroid-mount.service" ];
        };
      };

      virtualisation.waydroid = {
        enable = true;
        package = pkgs.waydroid-nftables;
      };
    };
}