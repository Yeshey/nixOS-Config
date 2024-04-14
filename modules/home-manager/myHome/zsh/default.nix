{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.zsh;
in
{
  options.myHome.zsh = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  # TODO make everything lib.mkDefault?

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = lib.mkDefault true;
      history = {
        size = lib.mkDefault 10000;
      };
      shellAliases = {
        ll = lib.mkDefault "eza -l --icons=auto";
        la = lib.mkDefault "eza -la --icons=auto";
      };
      # theme
      initExtraBeforeCompInit = ''
        # Completion
        zstyle ':completion:*' menu yes select

        # Prompt
        source ${pkgs.spaceship-prompt}/lib/spaceship-prompt/spaceship.zsh
        autoload -U promptinit; promptinit
      ''; 
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
        ZSH_AUTOSUGGEST_STRATEGY = [ "history" "completion" ];
        KEYTIMEOUT = 1;
        ZSHZ_CASE = "smart";
        ZSHZ_ECHO = 1;
      };
      
      enableAutosuggestions = lib.mkDefault true;
      enableCompletion = lib.mkDefault true;
      syntaxHighlighting.enable = lib.mkDefault true;
      enableVteIntegration = lib.mkDefault true;
      historySubstringSearch = {
        enable = lib.mkDefault true;
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
          src = "${pkgs.unstable.zsh-vi-mode}/share/zsh-vi-mode";
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
    home.file.".config/spaceship.zsh".source = ./spaceship.zsh;
  };
}
