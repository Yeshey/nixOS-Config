{
  inputs,
  ...
}:
{
  # import all essential nix-tools which are used in all modules of a specific class

  flake.modules.nixos.system-default = { lib, pkgs, ... }: {
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
      
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.system-default
    ];

    boot.tmp.cleanOnBoot = lib.mkDefault true;
    boot.supportedFilesystems = [ "ntfs" "btrfs" ];
    systemd.services.avahi-daemon = {
      serviceConfig.ExecStartPre = lib.mkBefore [
        "+${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid"
      ];
    };
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
        safe-rm
        gc
        nix-index-database
        secrets
        nix-your-shell
        restic-rclone-backups
      ]
      ++ [ inputs.self.modules.generic.systemConstants ];
  };
}