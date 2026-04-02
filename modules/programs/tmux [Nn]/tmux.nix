{
  flake.modules.nixos.tmux =
    {
      programs.tmux = {
        enable = true;
        escapeTime = 10;
        clock24 = true;
        terminal = "tmux-256color";
        extraConfig = ''
          set -g mouse on
          set -as terminal-features ",xterm-256color:RGB"
        '';
      };
    };

  flake.modules.darwin.tmux =
    {
      programs.tmux = {
        enable = true;
        enableMouse = true;          # darwin's dedicated mouse option
        extraConfig = ''
          set-option -g default-terminal "tmux-256color"
          set -g escape-time 10
          set -g clock-mode-style 24
          set -as terminal-features ",xterm-256color:RGB"
        '';
      };
    };

  flake.modules.homeManager.tmux =
    {
      programs.tmux = {
        enable = true;
        mouse = true;
        escapeTime = 10;
        clock24 = true;
        terminal = "tmux-256color";
        extraConfig = ''
          set -as terminal-features ",xterm-256color:RGB"
        '';
      };
    };
}