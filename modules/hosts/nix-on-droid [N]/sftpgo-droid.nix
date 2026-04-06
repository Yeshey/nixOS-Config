{ inputs, ... }:
{
  flake.modules.nixOnDroid.sftpgo-droid =
    { config, lib, pkgs, ... }:
    let
      port = 2022;
      binName = "sftpgo-start";
      authorizedKeysFiles = [ ./../../../id_ed_mykey.pub ];

      # Build "--public-key <contents>" args for each key file
      pubKeyArgs = lib.concatMapStrings
        (f: ''--public-key "$(cat ${f})" '')
        authorizedKeysFiles;

      sftpgo-start = pkgs.writeScriptBin binName ''
        #!${pkgs.runtimeShell}
        echo "Starting sftpgo on port ${toString port}, root: $HOME"
        echo "Android storage accessible via $HOME/storage symlink"
        nohup ${pkgs.sftpgo}/bin/sftpgo portable \
          --directory "$HOME" \
          --sftpd-port ${toString port} \
          --username "${config.user.userName}" \
          ${pubKeyArgs} \
          --permissions "*" \
          --log-level info \
          > /tmp/sftpgo.log 2>&1 &
        echo "sftpgo started (PID $!), logs: tail -f /tmp/sftpgo.log"
      '';
    in
    {
      environment.packages = [ sftpgo-start pkgs.sftpgo ];

      build.activationAfter.sftpgo = ''
        if ! ${pkgs.procps}/bin/pgrep -x sftpgo > /dev/null 2>&1; then
          $DRY_RUN_CMD ${sftpgo-start}/bin/${binName}
        fi
      '';
    };

  flake.modules.homeManager.sftpgo-droid =
    { pkgs, lib, ... }:
    {
      programs.zsh.initContent = lib.mkBefore ''
        ${pkgs.procps}/bin/pgrep -x sftpgo > /dev/null 2>&1 || sftpgo-start
      '';
    };
}