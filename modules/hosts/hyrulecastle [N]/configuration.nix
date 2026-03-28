{
  inputs,
  ...
}:
{
  flake.modules.nixos.hyrulecastle = {
    imports = with inputs.self.modules.nixos; [
      system-desktop
      gnome-full
      # plasma-full
      # cosmic
      systemd-boot
      bluetooth
      tpm2
      btrfs
      nvidia

      autossh-reverse-proxy
      i2p

      # hosting
      # speedtest-tracker
    ];

    hardware.nvidia.prime.busIds = {
      intel = "PCI:0:2:0";
      nvidia = "PCI:1:0:0";
    };

    my-scripts = {
      enable = true;
      flakeLocation = "/home/yeshey/.setup";
      # hostName auto-detected from networking.hostName
    };

    autossh-reverse-proxy = {
      enable     = true;
      remoteIP   = "143.47.53.175";
      remoteUser = "yeshey";
      port       = 2232;
    };

    networking.hostName = "hyrulecastle"; 
  };
}
