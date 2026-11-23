{
  flake.modules.nixos.gc = {
    # nix.gc = {
    #   automatic = true;
    #   options = "--delete-older-than 14d";
    #   dates = "weekly";
    # };

    nix.settings = { # make builds auto run garbage collection when below 10GB
      min-free = 10 * 1024 * 1024 * 1024;  # 10 GiB
      max-free = 100 * 1024 * 1024 * 1024; # 100 GiB
    };

    systemd.timers.nh-clean.timerConfig = {
      RandomizedDelaySec = "1h";
      FixedRandomDelay = true;  # same offset each run, stable across reboots
    };
    programs.nh = {
      enable      = true;
      clean.enable     = true;
      clean.dates      = "monthly";
      clean.extraArgs  = "--keep-since 21d --keep 3";
      flake       = "/home/yeshey/.setup";
    };
  };

  flake.modules.homeManager.gc = 
    { config, ... }: 
    {
      nix.settings = { # make builds auto run garbage collection when below 10GB
        min-free = 10 * 1024 * 1024 * 1024;
        max-free = 100 * 1024 * 1024 * 1024;
      };

      # nix.gc = {
      #   automatic = true;
      #   options = "--delete-older-than 14d";
      #   frequency = "weekly";
      # };

      programs.nh = {
        enable     = true;
        clean.enable    = true;
        clean.dates     = "monthly";
        clean.extraArgs = "--keep-since 21d --keep 3";
        flake = "${config.home.homeDirectory}/.setup";
      };
      systemd.user.timers.nh-clean.Timer = {
        RandomizedDelaySec = "1h";
        FixedRandomDelay = true;
      };
    };
}