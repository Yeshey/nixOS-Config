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

      # changing rm to safe-rm to prevent your dumb ass from deleting your PC
      home.packages = with pkgs; [ 
        coreutils-with-safe-rm
      ];
      programs.bash.enable = true; # makes work in bash
      programs.zsh.enable = true;
      home.shellAliases = {
        sudo="sudo "; # makes aliases work even with sudo behind
        rm = "${pkgs.safe-rm}/bin/safe-rm";
      };
      
    };
}
