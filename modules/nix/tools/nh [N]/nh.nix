{
  flake.modules.nixos.nh = 
    { pkgs, ... }:
    {
      security.sudo.extraConfig = ''
        Defaults env_keep += "NH_FLAKE NH_HOSTNAME"
      ''; 

      programs.nh = {
        enable = true;
      };

      environment.shellAliases = {
        sudo = "sudo "; # makes aliases work even with sudo behind
        "nix-build" = "${pkgs.nix-output-monitor}/bin/nom-build";
        "nix-shell" = "${pkgs.nix-output-monitor}/bin/nom-shell";
      };

      environment.systemPackages = with pkgs; [
        nix-output-monitor
      ];
    };

  flake.modules.homeManager.nh =
    { config, ... }:
    {
      programs.nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/.setup";
      };
    };
}