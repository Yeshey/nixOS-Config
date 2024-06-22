{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.zsh;
in
{
  options.myHome.zsh = with lib; {
    enable = mkEnableOption "zsh";
    starshipTheme = mkOption {
      type = types.str;
      default = "default";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {
    # theme from https://gitlab.com/pinage404/dotfiles
    programs.starship = {
      enable = true;
      settings = pkgs.lib.importTOML ./${cfg.starshipTheme}.toml; # or ./starship2.toml
      enableBashIntegration = lib.mkDefault false;
    };
    # Need these fonts for starship theme to work
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      safe-rm
      eza
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "RobotoMono"
          "SourceCodePro"
        ];
      })
      oxygenfonts
      source-sans-pro
    ];

    programs.zsh = {
      enable = lib.mkOverride 1010 true;
      history = {
        size = lib.mkOverride 1010 10000;
      };
      shellAliases = {
        ll = lib.mkOverride 1010 "eza -l --icons=auto";
        la = lib.mkOverride 1010 "eza -la --icons=auto";
      };
      # bash
      initExtra = ''
        source ${./kubectl.zsh}
        source ${./git.zsh}
        source ${./myAlias.zsh}

        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey '^[[Z' reverse-menu-complete

        # Workaround for ZVM overwriting keybindings
        zvm_after_init_commands+=("bindkey '^[[A' history-substring-search-up")
        zvm_after_init_commands+=("bindkey '^[OA' history-substring-search-up")
        zvm_after_init_commands+=("bindkey '^[[B' history-substring-search-down")
        zvm_after_init_commands+=("bindkey '^[OB' history-substring-search-down")
      '';
      localVariables = {
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=13,underline";
        ZSH_AUTOSUGGEST_STRATEGY = [
          "history"
          "completion"
        ];
        KEYTIMEOUT = 1;
        ZSHZ_CASE = "smart";
        ZSHZ_ECHO = 1;
      };

      autosuggestion.enable = lib.mkOverride 1010 true;
      enableCompletion = lib.mkOverride 1010 true;
      syntaxHighlighting.enable = lib.mkOverride 1010 true;
      enableVteIntegration = lib.mkOverride 1010 true;
      historySubstringSearch = {
        enable = lib.mkOverride 1010 true;
      };

      plugins = [
        {
          name = "nix-shell";
          src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
        }
        {
          name = "you-should-use";
          src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
        }
        {
          name = "zsh-vi-mode";
          src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
        }
        {
          name = "zsh-z";
          src = "${pkgs.zsh-z}/share/zsh-z";
        }
      ];
      /*
        oh-my-zsh = {
          enable = true;
          plugins = [ "git"
                      "colored-man-pages"
                      "alias-finder"
                      "command-not-found"
                      "urltools"
                      "bgnotify"];
          theme = "agnoster"; # robbyrussell # agnoster # frisk
        };
      */
    };
  };
}
