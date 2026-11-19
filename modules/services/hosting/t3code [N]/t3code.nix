{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.t3code =
    { lib, config, pkgs, ... }:
    {
      home.packages = [ pkgs.unstable.t3code ];

      systemd.user.services.t3code = {
        Unit.Description = "T3 Code headless server";
        Service = {
          ExecStart = "${pkgs.unstable.t3code}/bin/t3 serve --host 127.0.0.1 --port 3773";
          Restart = "on-failure";
          RestartSec = "5s";
          Environment = [
            "PATH=${
              lib.makeBinPath [
                pkgs.nodejs
                pkgs.git
                pkgs.bash
                pkgs.coreutils
                pkgs.gnutar
                pkgs.gzip
              ]
            }:${config.home.profileDirectory}/bin"
          ];
        };
        Install.WantedBy = [ "default.target" ];
      };
    };

  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      # start user manager at boot, no login needed
      users.users.yeshey.linger = true;
      home-manager.users.yeshey.imports = [ hm.t3code ];

      # Optional but recommended so headless browser screenshots have clean fonts
      fonts.packages = with pkgs; [
        noto-fonts
        liberation_ttf
      ];
    };
}