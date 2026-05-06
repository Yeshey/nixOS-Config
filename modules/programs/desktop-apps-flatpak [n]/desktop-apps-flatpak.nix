{ inputs, ... }:
{
  flake.modules.homeManager.desktop-apps-flatpak =
    {
      imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
      services.flatpak.packages = [
        # { appId = "io.github.kolunmi.Bazaar"; origin = "flathub"; } # Doesn't support user repos yet
        { appId = "dev.vencord.Vesktop"; origin = "flathub"; }
        { appId = "com.rafaelmardojai.Blanket"; origin = "flathub"; }
        { appId = "com.bitwarden.desktop"; origin = "flathub"; }
      ];
    };
}