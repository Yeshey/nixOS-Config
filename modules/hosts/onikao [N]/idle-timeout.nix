{
  flake.modules.nixos.onikao =
    { pkgs, ... }:
    let
      lockerScript = pkgs.writeShellScript "xautolock-locker" ''
        # Use absolute path to qdbus, ensures it's available
        ${pkgs.libsForQt5.qttools}/bin/qdbus org.kde.ksmserver /KSMServer logout 0 0 0
      '';

      notifierScript = pkgs.writeShellScript "xautolock-notifier" ''
        ${pkgs.libnotify}/bin/notify-send 'Idle timeout' 'Logging out in 30 seconds'
      '';
    in {
      # Enable xautolock
      services.xserver.xautolock.enable = true;

      # Time in minutes before lock command runs (e.g., 10 minutes)
      services.xserver.xautolock.time = 1;

      # The command to run when idle timeout is reached – now a canonical path
      services.xserver.xautolock.locker = "${lockerScript}";

      # Optional: run a notifier command before the locker (e.g., show a warning)
      services.xserver.xautolock.enableNotifier = true;
      services.xserver.xautolock.notify = 30; # seconds before lock to show notifier
      services.xserver.xautolock.notifier = "${notifierScript}";
    };
}