{ inputs, ... }:
{
  flake.modules.nixOnDroid.autossh-reverse-proxy-droid =
    { pkgs, ... }:
    let
      remoteIP   = "143.47.53.175";
      remoteUser = "yeshey";
      remotePort = 2234;
      pidFile = "/tmp/autossh-reverse-proxy.pid";

      autossh-reverse-proxy-bin = "autossh-reverse-proxy";

      autossh-reverse-proxy = pkgs.writeScriptBin autossh-reverse-proxy-bin ''
        #!${pkgs.runtimeShell}
        if [ -f ${pidFile} ] && kill -0 $(cat ${pidFile}) 2>/dev/null; then
          echo "autossh already running (pid $(cat ${pidFile})), skipping"
          exit 0
        fi

        ${pkgs.autossh}/bin/autossh \
          -M 0 \
          -f \
          -N \
          -o ExitOnForwardFailure=yes \
          -o ServerAliveInterval=60 \
          -o ServerAliveCountMax=3 \
          -R 0.0.0.0:${toString remotePort}:localhost:8022 \
          ${remoteUser}@${remoteIP} \
          && echo "Reverse proxy started" \
          || echo "WARNING: reverse proxy failed to start"
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

      environment.packages = [
        autossh-reverse-proxy
        pkgs.autossh
      ];
    };

  flake.modules.homeManager.autossh-reverse-proxy-droid =
    { lib, ... }:
    {
      programs.zsh = {
        initContent = lib.mkBefore ''
          autossh-reverse-proxy
        '';
      };
    };
}