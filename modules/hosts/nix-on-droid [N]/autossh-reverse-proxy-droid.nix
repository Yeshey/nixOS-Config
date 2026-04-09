{ inputs, ... }:
{
  flake.modules.nixOnDroid.autossh-reverse-proxy-droid =
    { pkgs, ... }:
    let
      remoteIP   = "143.47.53.175";
      remoteUser = "yeshey";
      remotePort = 2234;

      autossh-reverse-proxy-bin = "autossh-reverse-proxy";

      autossh-reverse-proxy = pkgs.writeScriptBin autossh-reverse-proxy-bin ''
        #!${pkgs.runtimeShell}

        echo "Starting reverse proxy..."
        setsid ${pkgs.autossh}/bin/autossh \
          -M 0 \
          -N \
          -o ExitOnForwardFailure=yes \
          -o ServerAliveInterval=60 \
          -o ServerAliveCountMax=3 \
          -R 0.0.0.0:${toString remotePort}:localhost:8022 \
          ${remoteUser}@${remoteIP} \
          > /tmp/autossh.log 2>&1 &
        disown
        echo "Reverse proxy started, logs: tail -f /tmp/autossh.log"
      '';
    in
    {
      home-manager.config =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            autossh-reverse-proxy-droid
          ];
        };

      build.activationAfter.autossh-reverse-proxy = ''
        if ! ${pkgs.procps}/bin/pgrep -x autossh > /dev/null 2>&1; then
          $DRY_RUN_CMD ${autossh-reverse-proxy}/bin/${autossh-reverse-proxy-bin}
        fi
      '';

      environment.packages = [
        autossh-reverse-proxy
        pkgs.autossh
      ];
    };

  flake.modules.homeManager.autossh-reverse-proxy-droid =
    { pkgs, lib, ... }:
    {
      programs.zsh.initContent = lib.mkBefore ''
        ${pkgs.procps}/bin/pgrep -x autossh > /dev/null 2>&1 || autossh-reverse-proxy
      '';
    };
}