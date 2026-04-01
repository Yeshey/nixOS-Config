{
  inputs,
  ...
}:
{
  # expansion of cli system for desktop use

  flake.modules.nixos.system-desktop = { pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      system-cli

      flatpak
      printing
      virt
      steam
      adb
      iphone
      appimage
      waydroid
      syncthing
    ];

    programs.gphoto2.enable = true; # to be able to access digital cameras
    networking.resolvconf.dnsExtensionMechanism = lib.mkDefault false; # https://github.com/NixOS/nixpkgs/issues/24433
    services.automatic-timezoned.enable = true;
    networking.networkmanager = {
      enable = true;
      plugins = [
        pkgs.networkmanager-openvpn
      ];
    };
    systemd.services.dhcpcd.enable = false; # Can cause conflict with network manager. For example, eduroam in ISCTE.
  };

  flake.modules.darwin.system-desktop = {
    imports = with inputs.self.modules.darwin; [
      system-cli
    ];
  };

  flake.modules.homeManager.system-desktop = {
    imports = with inputs.self.modules.homeManager; [
      system-cli

      desktop-apps
      firefox
      vscodium
      zed-editor
      syncthing
    ];
  };
}
