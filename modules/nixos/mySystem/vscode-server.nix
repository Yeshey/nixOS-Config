{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.vscode-server;
in
{
  imports = [ inputs.vscode-server.nixosModules.default ];

  options.mySystem.vscode-server = {
    enable = lib.mkEnableOption "vscode-server";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable)  {
    # https://github.com/nix-community/nixos-vscode-server/

    services.vscode-server.enable = true;

    # Override the auto-fix-vscode-server service to add an [Install] section.
    systemd.user.services.auto-fix-vscode-server = {
      enable = true;
      extraConfig = ''
        [Install]
        WantedBy=default.target
      '';
    };

    environment.systemPackages = with pkgs; [
      
    ];
  };
}
