{
  flake.modules.nixos.shell = 
    {
      pkgs,
      ...
    }:
    {
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
    ];
    programs.zsh.enable = true;
    environment = {
      shells = [ pkgs.zsh ];
      pathsToLink = [ "/share/zsh" ];
    };

    programs.bash = {
      enable = true;
      completion.enable = true;
    };

    users.defaultUserShell = pkgs.zsh;
  };

  flake.modules.homeManager.shell =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      flakePath = "${config.home.homeDirectory}/.setup";
    in
    {
      programs.zsh = {
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        historySubstringSearch.enable = true;
        enableCompletion = true;
        history.size = 100000;

        shellAliases = {
          l = "ls -l";
          la = "ls -a";
          lla = "ls -la";
          lt = "ls --tree";
          # Uses the dynamic path calculated above
          update = "sudo nh os switch --bypass-root-check ${flakePath} -- --max-jobs 2 --cores 5";
          update-re = "sudo bash -c 'nh os boot --bypass-root-check ${flakePath} -- --max-jobs 2 --cores 5 && reboot'";
          update-off = "sudo bash -c 'nh os boot --bypass-root-check ${flakePath} -- --max-jobs 2 --cores 5 && poweroff'";
        };

        initContent = lib.mkBefore ''
          ${lib.optionalString (builtins.pathExists ./git.zsh) (builtins.readFile ./git.zsh)}
          ${lib.optionalString (builtins.pathExists ./myAlias.zsh) (builtins.readFile ./myAlias.zsh)}

          # Keybindings for word navigation (standard for xterm-256color)
          bindkey "^[[1;5C" forward-word
          bindkey "^[[1;5D" backward-word
          bindkey '^[[Z' reverse-menu-complete

          # Plugin sources
          source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh
          source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
          source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
        '';

        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "colored-man-pages"
            "alias-finder"
            "urltools"
            "bgnotify"
          ];
          theme = "agnoster";
        };
      };

      home.packages = with pkgs; [
        zsh-nix-shell
        zsh-vi-mode
        zsh-you-should-use
      ];

      programs.bash = {
        enable = true;
        enableCompletion = true;
      };
    };

}
