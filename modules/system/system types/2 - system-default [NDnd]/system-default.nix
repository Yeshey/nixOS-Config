{
  inputs,
  ...
}:
{
  # import all essential nix-tools which are used in all modules of a specific class

  flake.modules.nixos.system-default = { pkgs, lib, ... }: {
    imports =
      with inputs.self.modules.nixos;
      [
        system-minimal
        home-manager
        safe-rm
        gc
        nix-index-database
        nix-ld
        location
        restic-rclone-backups
        zram
        secrets
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
        pkgs-by-name
      ]);

      boot.tmp.cleanOnBoot = lib.mkDefault true;
      boot.supportedFilesystems = [ "ntfs" "btrfs" ];
      programs.gphoto2.enable = true; # to be able to access digital cameras
      networking.resolvconf.dnsExtensionMechanism = lib.mkDefault false; # https://github.com/NixOS/nixpkgs/issues/24433
      services.automatic-timezoned.enable = true;
      networking.networkmanager = {
        enable = lib.mkOverride 1010 true;
        plugins = [
          pkgs.networkmanager-openvpn
        ];
      };
      systemd.services.dhcpcd.enable = false; # Can cause conflict with network manager. For example, eduroam in ISCTE.
  };

  flake.modules.darwin.system-default = {
    imports =
      with inputs.self.modules.darwin;
      [
        system-minimal
        determinate
        home-manager
        homebrew
        secrets
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
        pkgs-by-name
      ]);
  };

  # impermanence is not added by default to home-manager, because of missing Darwin implementation
  # for linux home-manager stand-alone configurations it has to be added manually

  flake.modules.homeManager.system-default = {
    imports =
      with inputs.self.modules.homeManager;
      [
        system-minimal
        safe-rm
        gc
        nix-index-database
        secrets
        nix-your-shell
      ]
      ++ [ inputs.self.modules.generic.systemConstants ];
  };
}