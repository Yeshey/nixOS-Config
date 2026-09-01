{
  flake.modules.nixos.onikao =
    { pkgs, lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/virtualisation/lxc-container.nix")
      ];
      networking = {
        dhcpcd.enable = false;
        useDHCP = false;
        useHostResolvConf = false;
      };
      systemd.network = {
        enable = true;
        networks."50-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };
      networking.networkmanager.enable = lib.mkForce false; # the container needs network set up exactly like above, don't let NetworkManager ruin it.
      systemd.services.systemd-networkd.restartIfChanged = false;
      systemd.services.NetworkManager.restartIfChanged = false;   # if still present
      systemd.services.tailscaled.restartIfChanged = false;
      systemd.services.sshd.restartIfChanged = false;
      security.wrappers.ping = { # makes ping work
        owner = "root";
        group = "root";
        capabilities = "cap_net_raw+ep";  # Grants the CAP_NET_RAW capability
        source = "${pkgs.iputils.out}/bin/ping";
      };
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # only needed if you'll run 32-bit apps/games via the GPU
      };
      hardware.amdgpu.opencl.enable = true;
      environment.systemPackages = [ pkgs.clinfo ];
      swapDevices = [ {
        device = "/var/lib/swapfile";
        size = 4 * 1024; # 16GB
      } ];
    };
}