{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };
}