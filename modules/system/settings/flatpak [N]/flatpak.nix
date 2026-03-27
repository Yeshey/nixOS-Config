{ inputs, ... }:
{
  flake.modules.nixos.flatpak = 
    { ... }:
    {
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

      services.flatpak = {
        enable = true;
        update.auto = {
          enable = true;
          onCalendar = "weekly"; # Default value
        };
      };

      # allow guest user, and other users to install flatpaks globally
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if ((subject.user === "guest" || subject.local) &&
              (action.id === "org.freedesktop.Flatpak.app-install" ||
              action.id === "org.freedesktop.Flatpak.runtime-install" ||
              action.id === "org.freedesktop.Flatpak.app-uninstall" ||
              action.id === "org.freedesktop.Flatpak.runtime-uninstall" ||
              action.id === "org.freedesktop.Flatpak.modify-repo")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
}