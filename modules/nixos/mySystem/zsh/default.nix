{ inputs, outputs, config, lib, pkgs, ... }:

let
  cfg = config.mySystem.zsh;
in
{
  options.mySystem.zsh = {
      enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = pkgs.lib.importTOML ./starship.toml;
    };
    # Need these fonts for starship theme to work
    fonts.fontconfig.enable = true;
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];
    environment = {
      systemPackages = with pkgs; [
        nerdfonts
        /*
        (
          nerdfonts.override {
            fonts = [
              "FiraCode"
              "RobotoMono"
              "SourceCodePro"
            ];
          }
        )*/
      ];
    };

    programs.zsh = {
      enable = lib.mkDefault true;
      autosuggestions.enable = lib.mkDefault true;
      syntaxHighlighting.enable = lib.mkDefault true;
      enableCompletion = lib.mkDefault true;
      histSize = lib.mkDefault 100000;
      shellAliases = {
        ll = lib.mkOverride 995 "eza -l --icons=auto"; # TODO add lib.mkOverride 995 everywhere
        la = lib.mkDefault "eza -la --icons=auto";
      };
      shellInit = ''
        autoload -U promptinit; promptinit
      '';
      interactiveShellInit = ''
        source ${./kubectl.zsh}
        source ${./git.zsh}
        source ${./myAlias.zsh}

        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey '^[[Z' reverse-menu-complete

        source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh
        source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
      '';
# TODO do I need to install them? Figure out
    #environment.systemPackages = with pkgs; [ 
    #  zsh-you-should-use
    #];

    };

    environment = {
      shells = [ pkgs.zsh ];
      pathsToLink = [ "/share/zsh" ];
    };
    users.defaultUserShell = lib.mkOverride 995 pkgs.zsh;

  };
}
