# TODO what is this
{
  home = rec {
    username = "mmieszczak";
    homeDirectory = "/home/${username}";
    stateVersion = "22.11";
  };

  myHome = {
    nonNixos.enable = true;
    gnome.enable = true;
    devops.enable = true;
    cli.personalGitEnable = false;
    tmux.enable = true;
    zsh.enable = true;
    neovim = {
      enable = true;
      enableLSP = true;
    };
  };

  nixpkgs.overlays = [ (filal: prev: { kubectl = prev.kubectl_1_26; }) ];

  # Workaround for freezing during activity switching on Ubuntu
  dconf.settings."org/gnome/desktop/interface".enable-animations = false;

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [ "forge@jmmaranan.com" ];
    };
    "org/gnome/shell/extensions/forge" = {
      tiling-mode-enabled = true;
      window-gap-size = 4;
      window-gap-size-increment = 1;
      window-gap-hidden-on-single = true;
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      screensaver = [ "<Shift><Control><Super>l" ];
    };
    "org/gnome/desktop/wm/keybindings" = {
      minimize = [ "<Shift><Control><Super>h" ];
      close = [ "<Super>x" ];
    };
  };
}
