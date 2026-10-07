{
  flake.modules.nixos.tailscale =
    {
      services.tailscale = {
        enable = true;
        permitCertUid = "caddy";
      };
    };
}