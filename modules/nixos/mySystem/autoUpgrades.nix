{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.autoUpgrades;
in
{
  options.mySystem.autoUpgrades = {
    enable = lib.mkEnableOption "autoUpgrades";
    location = lib.mkOption {
      default = "github:Yeshey/nixOS-Config";
      type = lib.types.str;
      example = "/home/yeshey/.setup";
      description = ''
        path to your flake config
      '';
    };
    host = lib.mkOption {
      type = lib.types.str;
      example = "kakariko";
      description = ''
        name of config to build
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    /*
          # TODO Fix & add auto Upgrades, also set it to boot
          # Auto Upgrade
          # a guy told you in nix wiki to make auto upgrades use boot, to be atomic, meaning, that if they get interrupted it's safe. But notice this:
      $ sudo nixos-rebuild switch --flake ~/.setup#skyloft && echo "success"
      [...]
      abr 08 22:00:50 nixos-skyloft systemd[1]: podman-mineclone-server.service: Consumed 162ms CPU time, received 16.2K IP traffic, sent 4.5K IP traffic.
      warning: error(s) occurred while switching to the new configuration

      $ sudo nixos-rebuild boot --flake ~/.setup#skyloft && echo "success"
      [...]
      warning: Git tree '/home/yeshey/.setup' is dirty
      success

      # this command makes a podman service fail, notice how I can detect that if fails with switch, but not with boot, if I want to detect that it fails and roll back in the automatic upgrades, I'll probably have to use switch
    */
    system.autoUpgrade = {
      enable = true;
      # dates = "23:01";
      dates = "weekly";
      flake = "${location}#${host}"; # my flake online uri is for example github:yeshey/nixos-config#laptop
      flags = [
        # "--upgrade --option fallback false --update-input nixos-hardware --update-input home-manager --update-input nixpkgs || (cd ${location} && git checkout --flake.lock)"

        # "--upgrade" (seems to be redundant) # upgrade NixOS to the latest version in your chosen channel
        # "--option fallback false" # fallback false should force it to use pre-built packages (https://github.com/NixOS/nixpkgs/issues/77971)
        # "--update-input nixos-hardware --update-input home-manager --update-input nixpkgs" # To update all the packages
        # "--commit-lock-file" # commit the new lock file with git
        # || cd ${location} && git checkout -- flake.lock '' # reverts the changes to flake.lock if things went south (doesn't work because the commands in this list they aren't placed in this order in the end)
      ];
      allowReboot = false; # set to false
      persistent = true; # upgrades even if PC was off when it would upgrade
    };
    /*
    systemd.services.nixos-upgrade.serviceConfig = let
      cfg = config.services.nixos-upgrade;
    in {
      # you can follow the service real time with journalctl -f -u nixos-upgrade.service
      # Also worth noting that these only apply to the physical RAM used,
      # they do not include swap space used.
      # (There is a separate MemorySwapMax setting, but no MemorySwapHigh, it seems.)
      # https://unix.stackexchange.com/questions/436791/limit-total-memory-usage-for-multiple-instances-of-systemd-service
      MemoryHigh = [ "500M" ];
      MemoryMax = [ "2048M" ];

      # https://unix.stackexchange.com/questions/494843/how-to-limit-a-systemd-service-to-play-nice-with-the-cpu
      CPUWeight = [ "20" ];
      CPUQuota = [ "85%" ];
      IOWeight = [ "20" ];
      # this doesn't work yet (https://unix.stackexchange.com/questions/441575/proper-way-to-use-onfailure-in-systemd)
      ExecStopPost= [ "sh -c 'if [ \"$$SERVICE_RESULT\" != \"success\" ]; then cd ${location} && git checkout -- flake.lock; fi'" ];
    };
    */
  };
}
