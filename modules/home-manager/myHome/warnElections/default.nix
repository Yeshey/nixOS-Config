{
  config,
  lib,
  pkgs,
  ...
}:

let 
myPython = pkgs.python312.withPackages (ps: with ps; [
  beautifulsoup4 requests numpy
]);
in 
let
  cfg = config.myHome.warnElections;
  electionScript = pkgs.writeScriptBin "check-elections" ''
    #!${myPython}/bin/python
    ${builtins.readFile ./searchElections.py}
  '';
in
{
  options.myHome.warnElections = {
    enable = lib.mkEnableOption "warnElections";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable && config.home.username != "guest")  {
    home.packages = [ 
      electionScript 
      myPython
    ];

    # Elections check service that waits for network-online
    systemd.user.services."warn-elections" = {
      Unit = {
        Description = "Check for upcoming elections";
        After = [ "my-network-online.service" ];
        Wants = [ "my-network-online.service" ];
        Requires = [ "my-network-online.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${electionScript}/bin/check-elections";
        Environment = "DISPLAY=:0";  # Needed for notifications to show up
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.timers."warn-elections" = {
      Unit = {
        Description = "Timer for election checker";
        PartOf = [ "warn-elections.service" ];
      };
      Timer = {
        #OnCalendar = "*-*-* *:*:00";      # Every minute at :00 seconds to test
        OnCalendar = "21:00:00";
        RandomizedDelaySec = "30s";
        AccuracySec = "1s";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

  };
}