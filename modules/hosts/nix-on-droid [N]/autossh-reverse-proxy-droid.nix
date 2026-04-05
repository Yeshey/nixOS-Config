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
      programs.zsh = {
        programs.zsh.initContent = lib.mkBefore ''
          ${pkgs.procps}/bin/pgrep -x autossh > /dev/null 2>&1 || autossh-reverse-proxy
        '';
      };
    };
}