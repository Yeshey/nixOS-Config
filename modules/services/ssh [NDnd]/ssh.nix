{
  flake.modules.nixos.ssh =
    {
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          # PasswordAuthentication = true;
          # PermitRootLogin = "yes";
          StreamLocalBindUnlink = "yes"; # Allows new tunnels to take over ports if the old one is stale
          GatewayPorts = "clientspecified"; # Allows connecting to tunnels from outside the server
          X11Forwarding = true;
          ClientAliveInterval = 300;
          ClientAliveCountMax = 3;
        };
      };

      programs.ssh = {
        forwardX11 = true;
        extraConfig = builtins.readFile ./config; 
      };
    };

  flake.modules.homeManager.ssh =
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*" = {
          forwardAgent = true;
          compression = true;
          serverAliveInterval = 120;
        };
        extraConfig = builtins.readFile ./config; 
      };
    };

  flake.modules.darwin.ssh = {
    services.openssh = {
      enable = true;
    };
  };
}