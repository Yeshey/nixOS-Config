{ inputs, outputs, config, lib, pkgs, ... }:

let
  cfg = config.mySystem.zsh;
in
{
  options.mySystem.zsh = {
      enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf cfg.enable {

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
      shellInit = lib.mkDefault ''
        autoload -U promptinit; promptinit
      '';
      interactiveShellInit = lib.mkDefault ''
        source ${./kubectl.zsh}
        source ${./git.zsh}
        source ${./myAlias.zsh}

        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey '^[[Z' reverse-menu-complete

        source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh
      '';

      ohMyZsh = {
        enable = lib.mkDefault true;
        plugins = [ "git" 
                    "colored-man-pages" 
                    "alias-finder" 
                    "command-not-found" 
                    "urltools" 
                    "bgnotify"
                    "you-should-use"
                  ];
        theme = lib.mkDefault "agnoster"; # robbyrussell # agnoster # frisk
        customPkgs = with pkgs; [
          zsh-you-should-use
        ];
      };
    };

    environment.systemPackages = with pkgs; [ 
      zsh-you-should-use
    ];

    environment = {
      shells = [ pkgs.zsh ];
      pathsToLink = [ "/share/zsh" ];
    };
    users.defaultUserShell = lib.mkOverride 995 pkgs.zsh;

  };
}
