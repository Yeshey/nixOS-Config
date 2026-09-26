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
      tailscale

      yeshey-syncthing

      i2p
      ollama-cuda

      # hosting
      # speedtest-tracker
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.hyrulecastle
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

    boot.zswap.maxPoolPercent = 50;

    # networking.firewall.enable = false;

    networking.hostName = "hyrulecastle";
  };
  flake.modules.homeManager.hyrulecastle = { };
}
