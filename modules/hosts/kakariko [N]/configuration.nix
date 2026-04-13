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
      btrfs

      autossh-reverse-proxy
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

    autossh-reverse-proxy = {
      enable     = true;
      remoteIP   = "143.47.53.175";
      remoteUser = "yeshey";
      port       = 2233;
    };

    boot.zswap.maxPoolPercent = 50;

    networking.hostName = "kakariko"; 
  };
  flake.modules.homeManager.kakariko = { };
}
