{ pkgs, ... }:
{
  # connect with ssh nix-on-droid@192.168.1.254 -p 8022
  # (will not be able to exit app, will have to kill it in android)
  services.openssh = {
    enable = true;
    ports = [ 8022 ];
    authorizedKeysFiles = [
      (pkgs.writeText "id_ed25519.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGlaGOK+qN0/Fk0d2bVdRTNncfQwxaEofoOnKgwK95s")
    ];
  };
}
