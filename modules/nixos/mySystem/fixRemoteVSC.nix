{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.fixRemoteVSC;
in
{
  imports = [ inputs.vscode-server.nixosModules.default ];

  options.mySystem.fixRemoteVSC = with lib; {
    enable = mkEnableOption "fixRemoteVSC";

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Users to enable the VS Code remote server fix for.
        The auto-fix service will be started at boot for each of these
        users, regardless of whether they are logged in.
      '';
      example = [ "yeshey" ];
    };
  };

  config = lib.mkMerge [
    { }
    (lib.mkIf (config.mySystem.enable && cfg.enable) {

      # This installs the auto-fix-vscode-server.service unit into
      # /run/current-system/etc/systemd/user/ so it's available system-wide
      services.vscode-server.enable = true;

      # Enable linger for each user: their user services (including
      # auto-fix-vscode-server) will start at boot and keep running
      # even when nobody is logged in via SSH
      systemd.tmpfiles.rules = map
        (user: "f /var/lib/systemd/linger/${user} 0644 root root -")
        cfg.users;

      # Symlink the service into each user's systemd wants directory so it
      # is automatically enabled without them having to run
      # `systemctl --user enable` manually.
      # We point at /run/current-system/... so it survives garbage collection.
      system.activationScripts.enableVSCodeServerForUsers =
        lib.stringAfter [ "users" "groups" ]
          (lib.concatMapStrings
            (user: ''
              mkdir -p /home/${user}/.config/systemd/user/default.target.wants
              ln -sfT /run/current-system/etc/systemd/user/auto-fix-vscode-server.service \
                /home/${user}/.config/systemd/user/default.target.wants/auto-fix-vscode-server.service
            '')
            cfg.users);
    })
  ];
}