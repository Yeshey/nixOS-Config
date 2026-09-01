{
  inputs,
  ...
}:
{
  flake.modules.nixos.onikao = 
  { pkgs, ... }:
  {
    imports = with inputs.self.modules.nixos; [
      system-desktop
      plasma-full
      systemd-boot
      tailscale

      # box64-binfmt

      # hosting
      # speedtest-tracker
      # code-server
      xrdp
      vscodium
      # jupyter
      # ollama
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.onikao
    ];
    nixpkgs.config.allowUnsupportedSystem = true;
    nixpkgs.config.allowBroken = true;

    environment.systemPackages = with pkgs; [
      github-desktop
    ];

    my-scripts = {
      enable = true;
      flakeLocation = "/home/yeshey/.setup";
    };

    services.openssh = {
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "no";
      settings.PerSourcePenalties = "no"; # sometimes killed reverse proxy tunnels
    };

    networking.hostName = "onikao"; 
  };
  flake.modules.homeManager.onikao = { };
}
