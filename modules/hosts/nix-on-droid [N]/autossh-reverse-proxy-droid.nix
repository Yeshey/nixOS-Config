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
          -R ${toString remotePort}:localhost:8022 \
          ${remoteUser}@${remoteIP} \
          && echo "Reverse proxy started: ${remoteUser}@${remoteIP} port ${toString remotePort}" \
          || echo "WARNING: reverse proxy failed to start, you won't be able to reach this device remotely"
      '';
    in
    {
      # TODO, is there a difference between home-manager.config and home-manager.sharedModules here?
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