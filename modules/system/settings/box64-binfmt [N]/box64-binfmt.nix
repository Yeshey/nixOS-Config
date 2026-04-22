{inputs, ... }:
{
  flake.modules.nixos.box64-binfmt =
    { pkgs, ... }:
    {
      # nixpkgs.overlays = [
      #   inputs.box64-binfmt.overlays.default 
      # ];

      # # Required so the build system can cross-compile the box32 package before
      # # binfmt registration is active.  Rebuild once with enable = false first.
      # boot.binfmt.emulatedSystems = [
      #   "i386-linux" "i486-linux" "i586-linux" "i686-linux"
      #   "x86_64-linux"
      # ];
      # nix.settings.extra-platforms = [
      #   "i386-linux" "i486-linux" "i586-linux" "i686-linux"
      #   "x86_64-linux"
      # ];

      box64-binfmt.enable = true;

      environment.systemPackages = [
        pkgs.x86.cowsay
        pkgs.x86.vectoroids
      ];
    };
}
