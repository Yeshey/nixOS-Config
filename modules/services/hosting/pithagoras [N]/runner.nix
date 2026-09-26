{
  flake.modules.nixos.pithagoras =
    {
      sops.secrets.forgejo_agent_token = {
        path = "/var/lib/pithagoras/workspaces/forgejo-admin/.secrets/forgejo-token";
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/pithagoras/workspaces/forgejo-admin/.secrets 0700 root root -"
      ];
    };
}