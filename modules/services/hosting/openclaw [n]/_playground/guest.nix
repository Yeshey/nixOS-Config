{ pkgs, ... }: {
  # imports = [ ./litellm-test.nix ];  # disabled after test
  environment.systemPackages = [ pkgs.cowsay pkgs.cmatrix ];

  # sops.secrets.gemini_api_key = {
  #   owner = "openclaw";
  #   mode = "0400";
  # };

  home-manager.users.openclaw.programs.openclaw.config.skills.load.extraDirs = [
    "/home/openclaw/projects/nixOS-Config/modules/services/hosting/openclaw [n]/_playground/skills"
  ];
}
