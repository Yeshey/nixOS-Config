{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.cowsay pkgs.cmatrix ];
}