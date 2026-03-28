{
  inputs,
  ...
}:
{
  # expansion of cli system for desktop use

  flake.modules.nixos.system-desktop = {
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
      my-scripts
      syncthing
    ];
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
      firefox-browser
      vscodium
      zed-editor

      my-scripts
      syncthing
    ];
  };
}
