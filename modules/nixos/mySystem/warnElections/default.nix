{
  config,
  lib,
  pkgs,
  ...
}:

let 
myPython = (pkgs.python311.withPackages (python-pkgs: with python-pkgs; [
        beautifulsoup4
        requests
        numpy
      ]));
in 
let
  cfg = config.mySystem.warnElections;
  electionScript = pkgs.writeScriptBin "check-elections" ''
    #!${myPython}/bin/python
    ${builtins.readFile ./searchElections.py}
  '';
in
{
  options.mySystem.warnElections = {
    enable = lib.mkEnableOption "warnElections";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable)  {
    environment.systemPackages = [ 
      electionScript 
      myPython
    ];

    systemd.user.services.warn-elections = {
      path = [ pkgs.libnotify ];
      description = "Check for upcoming elections";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${electionScript}/bin/check-elections";
        Environment="DISPLAY=:0";  # Needed for notifications to show up
      };
    };

    systemd.user.timers.warn-elections = {
      description = "Timer for election checker";
      partOf = [ "warn-elections.service" ];
      timerConfig = {
        Unit = "warn-elections.service";
        #OnCalendar = "*-*-* *:*:00";      # Every minute at :00 seconds to test
        #RandomizedDelaySec = "5s";        # Small random delay to prevent clustering
        #AccuracySec = "1s";               # Highest possible accuracy

        OnCalendar = "00/5:00:00";          # Every 5 days at midnight
        RandomizedDelaySec = "6h";          # Spread over 6 hour windo
        Persistent = true;                # Run if missed last execution
        FixedRandomDelay = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}