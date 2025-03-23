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

    # need my own fucking service for this to start after internet is up
    systemd.services.my-network-online = {
      wantedBy = [ "multi-user.target"];
      path = [ pkgs.iputils ];
      script = ''
        until ${pkgs.iputils}/bin/ping -c1 google.com ; do ${pkgs.coreutils}/bin/sleep 5 ; done
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
    systemd.user.services.warn-elections = {
      wants = [ "nss-lookup.target" "my-network-online.service"];
      after = [ "nss-lookup.target" "my-network-online.service"];

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

        OnCalendar = "21:00:00";          # Every day at 21:00
        #RandomizedDelaySec = "6h";        # Spread over 6 hour window
        #Persistent = true;               # Run if missed last execution
        #FixedRandomDelay = true;

        # High accuracy
        #OnCalendar = "*-*-* *:0/5:00";     # Every 5 minutes at :00 seconds
        RandomizedDelaySec = "30s";       # Max 30-second random delay
        AccuracySec = "1s";               # High precision
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}