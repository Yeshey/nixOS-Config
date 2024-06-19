# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.

{
  myHome = import ./myHome;
  default = {
      inputs,
      config,
      lib,
      pkgs,
      ...
    }:{
      # Nicely reload system units when changing configs
      systemd.user.startServices = lib.mkOverride 1010 "sd-switch";
    };
}
