{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.cli.tmux;
in
{
  options.myHome.homeApps.cli.tmux = with lib; {
    enable = mkEnableOption "tmux";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && config.myHome.homeApps.cli.enable && cfg.enable) {
    programs.tmux = {
      enable = true;
      prefix = "C-b";
      terminal = "tmux-256color";
      keyMode = "vi";
      escapeTime = 10;
      newSession = true;
      plugins = with pkgs; [
        tmuxPlugins.yank
        {
          plugin = tmuxPlugins.power-theme;
          extraConfig = ''
            set -g @tmux_power_theme '#99C794'
          '';
        }
      ];
      extraConfig = ''
        # TERM override
        set terminal-overrides "xterm*:RGB"

        # Enable mouse
        set -g mouse on

        # Pane movement shortcuts (same as vim)
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Copy mode using 'Esc'
        unbind [
        bind Escape copy-mode

        # Start selection with 'v' and copy using 'y'
        bind-key -T copy-mode-vi v send-keys -X begin-selection

        # Custom
        bind-key -r i run-shell "tmux neww ollama run mistral:instruct"
      '';
    };
  };
}
