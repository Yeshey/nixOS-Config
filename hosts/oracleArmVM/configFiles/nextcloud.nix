{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
    imports = [
        # ...
    ];

    # NextCloud
    services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud26;
        hostName = "143.47.53.175";
        # Enable built-in virtual host management
        # Takes care of somewhat complicated setup
        # See here: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-apps/nextcloud.nix#L529

        enableBrokenCiphersForSSE = false;

        # Use HTTPS for links
        # https = true;
        
        # Auto-update Nextcloud Apps
        autoUpdateApps.enable = true;
        # Set what time makes sense for you
        autoUpdateApps.startAt = "05:00:00";

        config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}"; # user: root, pass: test123
    };

    # networking.firewall.enable = false;
    networking.firewall.allowedTCPPorts = [ 80 443 ];

}
