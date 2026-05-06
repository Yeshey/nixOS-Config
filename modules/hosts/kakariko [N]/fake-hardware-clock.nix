{
  flake.modules.nixos.fake-hardware-clock =
    { pkgs, ... }:
    {
      # 1. Disable the hardware clock entirely 
      # Assuming hardware clock is broken, we prevent NixOS from trying to read/write to it.
      systemd.services.systemd-hwclock-save.enable = false;
      systemd.services.systemd-hwclock-load.enable = false;

      # 2. Restore time from disk early in boot (Offline Fix)
      systemd.services.restore-persistent-clock = {
        description = "Restore time from file before network is up";
        before = [ "time-sync.target" "sysinit.target" ];
        wantedBy = [ "sysinit.target" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          CLOCK_FILE=/var/lib/persistent-clock
          if [ -f "$CLOCK_FILE" ]; then
            LAST_TIME=$(${pkgs.coreutils}/bin/stat -c %Y "$CLOCK_FILE")
            ${pkgs.coreutils}/bin/date -s "@$LAST_TIME"
          fi
        '';
      };

      # 3. Fix time with online server if there is internet
      systemd.services.fix-surface-clock = {
        description = "Fix broken Surface RTC using ntpdate";
        before = [ "time-sync.target" ];
        wants = [ "time-sync.target" "network-online.target" ];
        after = [ "network-online.target" ];
        unitConfig = {
          DefaultDependencies = false;
        };
        script = ''
          ${pkgs.ntp}/bin/ntpdate -u pool.ntp.org || ${pkgs.ntp}/bin/ntpdate -u time.google.com
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true; 
          Restart = "on-failure";
          RestartSec = "10s";
        };
        # This ensures time-sync.target is only reached after this finishes successfully
        wantedBy = [ "multi-user.target" "time-sync.target" ];
      };

      # 4. Periodically save the system time to the file
      systemd.timers.save-persistent-clock = {
        description = "Timer to save system time for persistent clock";
        timerConfig = {
          OnCalendar = "*:00/15"; # Save every 15 mins
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      systemd.services.save-persistent-clock = {
        description = "Save system time to persistent file";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/touch /var/lib/persistent-clock";
          # Also save the time specifically when shutting down
          ExecStop = "${pkgs.coreutils}/bin/touch /var/lib/persistent-clock";
          RemainAfterExit = true;
        };
      };

      # Create the state directory if it doesn't exist
      systemd.tmpfiles.rules = [
        "d /var/lib/ 0755 root root -"
      ];
    };
}