{
  # connect with ssh nix-on-droid@192.168.1.254 -p 8022
  # (will not be able to exit app, will have to kill it in android)
  services.openssh = {
    enable = true;
    ports = [ 8022 ];
    authorizedKeysFiles = [
      ./../../id_ed_mykey.pub
    ];
  };
}
