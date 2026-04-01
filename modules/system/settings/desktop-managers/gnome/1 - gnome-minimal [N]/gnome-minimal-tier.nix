{
  flake.modules.nixos.gnome-minimal-tier =
    { lib, ... }:
    {
      systemConstants.isGnome = true;
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;
      programs.ssh.startAgent = lib.mkForce false;
    };

  flake.modules.homeManager.gnome-minimal-tier = { };
}