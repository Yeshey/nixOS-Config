{ inputs, outputs, config, lib, pkgs, ... }:

let
  cfg = config.mySystem.zsh;
in
{
  options.mySystem.zsh = {
      enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        eza
        (
          nerdfonts.override {
            fonts = [
              "FiraCode"
            ];
          }
        )
      ];
    };
    #programs.starship = {
    #  enable = true;
    #  settings = pkgs.lib.importTOML ./starship.toml;
    #};

    programs.zsh = {
      enable = lib.mkDefault true;
      autosuggestions.enable = lib.mkDefault true;
      syntaxHighlighting.enable = lib.mkDefault true;
      enableCompletion = lib.mkDefault true;
      histSize = lib.mkDefault 100000;
      shellAliases = {
        ll = lib.mkOverride 995 "eza -l --icons=auto";
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
      ohMyZsh = {
        enable = true;
        plugins = [ "git" 
                    "colored-man-pages" 
                    "alias-finder" 
                    "command-not-found" 
                    "urltools" 
                    "bgnotify"];
        theme = "agnoster"; # robbyrussell # agnoster # frisk
      };
    };

    environment = {
      shells = [ pkgs.zsh ];
      pathsToLink = [ "/share/zsh" ];
    };
    users.defaultUserShell = lib.mkOverride 995 pkgs.zsh;

  };
}
