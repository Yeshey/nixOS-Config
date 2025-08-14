# routl all traffic through tor
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.allTor;
in
{
  options.mySystem.allTor = {
    enable = (lib.mkEnableOption "allTor");
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    services.tor = {
      enable        = true;
      client.enable = true;   # 9050 (slow) + 9063 (fast) SOCKS
    };

  };
}
