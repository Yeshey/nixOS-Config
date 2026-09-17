{
  inputs,
  ...
}:
{
  flake.modules.nixos.kakariko = {
    imports = with inputs.self.modules.nixos; [
      system-desktop
      gnome-full
      # plasma-full
      # cosmic
      systemd-boot
      bluetooth
      tpm2
      tailscale

      yeshey-syncthing

      # i2p

      # hosting
      # speedtest-tracker
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.kakariko
    ];

    my-scripts = {
      enable = true;
      flakeLocation = "/home/yeshey/.setup";
      # hostName auto-detected from networking.hostName
    };

    boot.zswap.maxPoolPercent = 55;

    networking.hostName = "kakariko"; 
  };
  flake.modules.homeManager.kakariko = { };
}
