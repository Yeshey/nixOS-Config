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

  config = lib.mkIf (config.myHome.enable && cfg.enable)  {
    home.packages = [ 
      electionScript 
      myPython
    ];

    # Wait for network online service
    systemd.user.services."my-network-online" = let
      script = pkgs.writeShellScriptBin "my-network-online-script" ''
        until ${pkgs.iputils}/bin/ping -c1 google.com ; do ${pkgs.coreutils}/bin/sleep 5 ; done
      '';
    in {
      Unit = {
        Description = "Wait for network online";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${script}/bin/my-network-online-script";
      };
      Install.WantedBy = [ "default.target" ];
    };

    # Elections check service that waits for network-online
    systemd.user.services."warn-elections" = {
      Unit = {
        Description = "Check for upcoming elections";
        After = [ "nss-lookup.target" "my-network-online.service" ];
        Wants = [ "nss-lookup.target" "my-network-online.service" ];
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