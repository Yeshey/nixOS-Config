# ./chrony.nix
{ config, pkgs, lib, ... }:

let
  #########################################################################
  # HTTPS-time helper (TLS handshake with Google, extract SERVER-HELLO time)
  #########################################################################
  tlsdate = pkgs.writeScriptBin "chrony-tlsdate" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    HOST=time.google.com
    PORT=443
    # seconds since epoch that the remote side sent in its TLS handshake
    SECONDS=$(${pkgs.openssl}/bin/openssl s_client -connect $HOST:$PORT \
                -servername $HOST < /dev/null 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -m1 '^ *${pkgs.gawk}/bin/awk '{print $1}' \
              | ${pkgs.coreutils}/bin/date -u -f - +%s 2>/dev/null)
    # set system clock (CAP_SYS_TIME is granted by systemd)
    ${pkgs.coreutils}/bin/date -s @$SECONDS
    # tell chrony we just stepped the clock so it can reset its filters
    ${pkgs.chrony}/bin/chronyc makestep
  '';

in
{
  ###########################################################################
  # 1.  chrony itself – plain UDP/123 only, no NTS, no early initstepslew
  ###########################################################################
  services.chrony = {
    enable            = true;
    enableRTCTrimming = true;
    enableNTS         = false;          # TCP/4460 is blocked anyway
    initstepslew = {
      enabled   = false;                # we do our own stepping if needed
      threshold = 1000;                 # unused but module wants a value
    };

    # four pool addresses are enough – remove iburst so we do not spam
    servers = [
      "0.pool.ntp.org"
      "1.pool.ntp.org"
      "2.pool.ntp.org"
      "3.pool.ntp.org"
    ];

    # extra safety: wait for network stack before chronyd starts
    extraConfig = ''
      # do not treat offline sources as fatal at start-up
      offline

      # our normal server lines
      server 0.pool.ntp.org
      server 1.pool.ntp.org
      server 2.pool.ntp.org
      server 3.pool.ntp.org

      # invoke helper on every source going offline/online
      poll 1 offline /run/chrony/poll-helper
    '';
  };

  ###########################################################################
  # 2.  systemd service: “if chrony has no selectable source → HTTPS-time”
  ###########################################################################
  systemd.services.chrony-tlsdate = {
    description = "Fallback HTTPS-time sync when UDP/123 is blocked";
    path        = [ pkgs.openssl pkgs.gnugrep pkgs.gawk pkgs.coreutils pkgs.chrony ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${tlsdate}/bin/chrony-tlsdate";
      # allow setting the clock
      CapabilityBoundingSet = "CAP_SYS_TIME";
      AmbientCapabilities   = "CAP_SYS_TIME";
      PrivateTmp            = true;
      ProtectSystem         = "strict";
      NoNewPrivileges       = false;
    };
  };

  systemd.timers.chrony-tlsdate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:*:0/2";              # every two minutes
      Unit       = "chrony-tlsdate.service";
      # run ONLY while chrony has NO selectable source
      ConditionPathExists = "!/run/chrony/polling-offline";
    };
  };

  ###########################################################################
  # 3.  tiny helper script that creates/removes the flag file
  #     (chrony calls poll scripts every time the online status changes)
  ###########################################################################
  systemd.services.chrony-poll-helper = {
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'touch /run/chrony/polling-offline'";
      ExecStop  = "${pkgs.bash}/bin/bash -c 'rm -f /run/chrony/polling-offline'";
      RemainAfterExit = true;
      RuntimeDirectory = "chrony";
    };
  };

  ###########################################################################
  # 5.  start chronyd only after the network stack is up (interface + routes)
  ###########################################################################
  systemd.services.chronyd = {
    after  = [ "network.target" ];
    wants  = [ "network.target" ];
    serviceConfig = {
      TimeoutStartSec = "60";
      Restart         = "on-failure";
      RestartSec      = "5";
    };
  };
}