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
    falkeLocation = lib.mkOption {
      default = "/home/yeshey/.setup";
      type = lib.types.str;
      example = "/home/yeshey/.setup";
      description = ''
        The location of your flake to make the update and upgrade command aliases work
      '';
    };
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
      };
      shellInit = ''
        autoload -U promptinit; promptinit
      '';
      interactiveShellInit = ''
        source ${./kubectl.zsh}
        source ${./git.zsh}
        source ${builtins.toFile "myAlias.zsh" (builtins.readFile ./myAlias.zsh + ''
          # complex alias that need nix syntax
          alias update="sudo nixos-rebuild --flake ${cfg.falkeLocation}#${config.mySystem.host} switch"
          alias update-re="sudo nixos-rebuild --flake ${cfg.falkeLocation}#${config.mySystem.host} boot && reboot"
          upgrade() {
              trap "cd '${cfg.falkeLocation}' && git checkout -- flake.lock" INT # if interrupted

              # Ask for password upfront
              sudo -v

              nix flake update "${cfg.falkeLocation}"

              if sudo nixos-rebuild switch --flake "${cfg.falkeLocation}#${config.mySystem.host}"; then
                  echo "NixOS upgrade successful."
              else
                  echo "Unable to update all flake inputs, trying to update just nixpkgs"
                  if sudo nixos-rebuild switch --flake "${cfg.falkeLocation}#${config.mySystem.host}" \
                      --update-input nixpkgs; then
                      echo "NixOS upgrade with nixpkgs update successful."
                  else
                      echo "NixOS upgrade failed. Rolling back changes to flake.lock"
                      cd "${cfg.falkeLocation}" && git checkout -- flake.lock
                  fi
              fi
          }
        '')}


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
