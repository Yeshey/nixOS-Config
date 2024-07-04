{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.zsh;
in
{
  options.mySystem.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    environment = {
      systemPackages = with pkgs; [ (nerdfonts.override { fonts = [ "FiraCode" ]; }) ];
    };
    #programs.starship = {
    #  enable = true;
    #  settings = pkgs.lib.importTOML ./starship.toml;
    #};

    programs.zsh = {
      enable = lib.mkOverride 1010 true;
      autosuggestions.enable = lib.mkOverride 1010 true;
      syntaxHighlighting.enable = lib.mkOverride 1010 true;
      enableCompletion = lib.mkOverride 1010 true;
      histSize = lib.mkOverride 1010 100000;
      shellAliases = {
        l = "ls -l";
        la = "ls -a";
        lla = "ls -la";
        lt = "ls --tree";

        #ll = lib.mkOverride 995 "eza -l --icons=auto";
        #la = lib.mkOverride 1010 "eza -la --icons=auto";
      };
      shellInit = ''
        autoload -U promptinit; promptinit
      '';
      interactiveShellInit = ''
        source ${./kubectl.zsh}
        source ${./git.zsh}
        source ${builtins.toFile "myAlias.zsh" (builtins.readFile ./myAlias.zsh)}

        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey '^[[Z' reverse-menu-complete

        source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh # doesn't seem to work?
        source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
      '';
      ohMyZsh = {
        enable = true;
        plugins = [
          "git"
          "colored-man-pages"
          "alias-finder"
          "command-not-found"
          "urltools"
          "bgnotify"
        ];
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
