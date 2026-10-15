{ pkgs, ... }: {
  # Optional: imports = [ ./litellm-test.nix ];
  environment.systemPackages = [ pkgs.cowsay pkgs.cmatrix ];
}
