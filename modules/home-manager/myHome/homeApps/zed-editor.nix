{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.zed-editor;
in
{
  options.myHome.homeApps.zed-editor = with lib; {
    enable = mkEnableOption "zed-editor";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

    home.packages = with pkgs; [
      nil # <-- language server
      nixfmt-rfc-style
      kdePackages.okular
    ];

    # zathura was a pdf reader that could integrate with zed, but problems like not opening links made me drop it
    # Instead use okular and in settings > Editor, set custom and Command: `zeditor %f:%l`
    # programs.zathura = {
    #   enable = true;
    #   package = pkgs.zathura;
    #   options = {
    #     synctex = true;
    #     sandbox = "none";
    #     double-click-follow = false;  # <-- single-click follows links
    #     synctex-editor-command = "${pkgs.zed-editor}/bin/zeditor %{input}:%{line}"; # Inverse search
    #   };
    # };


    programs.zed-editor = {
      installRemoteServer = true;
      enable = true;
      package = pkgs.unstable.zed-editor;
      extensions = [
        "nix"
        "toml"
        "rust"
        "latex"
        "react-typescript-snippets"
        "codebook"
        "git-firefly" # .gitignore and git formatting
        "make" # Makefile
      ];
      userSettings = {
        hour_format = "hour24";
        # vim_mode = true;
        # Tell Zed to use direnv and direnv can use a flake.nix environment
        load_direnv = "shell_hook";
        base_keymap = "VSCode";

        # Auto-save after 1 sec of inactivity
        autosave = {
          after_delay = {
            milliseconds = 1000;
          };
        };

        # ---------- LaTeX ----------
        # LaTeX
        lsp = {
          texlab = {
            settings = {
              texlab = {
                build = {
                  onSave = true;
                  forwardSearchAfter = true;
                  executable = "latexmk";
                  args = [
                    "--shell-escape"
                    "-f"
                    "-synctex=1"
                    "-interaction=nonstopmode"
                    "-file-line-error"
                    "-lualatex"
                    "%f"
                  ];
                };
                forwardSearch = {
                  executable = "okular";
                  args = [
                    "--unique"
                    "%p#src:%l%f"
                  ];
                };
              };
            };
          };
          # "codebook" = {
          #   "initialization_options" = {
          #     "logLevel" = "debug";
          #   };
          # };
        };

        languages = {
          "LaTeX" = {
            # Enable word wrap for LaTeX files only
            soft_wrap = "editor_width";
          };
        };

      };
    };

  };
}
