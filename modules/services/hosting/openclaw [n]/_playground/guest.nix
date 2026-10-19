{ pkgs, ... }: {
  # imports = [ ./litellm-test.nix ];  # disabled after test
  sops.secrets.opencode_key = {
    owner = "openclaw";
    mode = "0400";
  };
  environment.systemPackages = [ pkgs.cowsay pkgs.cmatrix ];

  home-manager.users.openclaw.programs.openclaw.config.skills.load.extraDirs = [
    "/home/openclaw/projects/nixOS-Config/modules/services/hosting/openclaw [n]/_playground/skills"
  ];
}
