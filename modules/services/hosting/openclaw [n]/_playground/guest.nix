{ pkgs, ... }: {
  imports = [ ./litellm-test.nix ];  # enabled for testing
  environment.systemPackages = [ pkgs.cowsay pkgs.cmatrix ];

  home-manager.users.openclaw.programs.openclaw.config.skills.load.extraDirs = [
    "/home/openclaw/projects/nixOS-Config/modules/services/hosting/openclaw [n]/_playground/skills"
  ];
}
