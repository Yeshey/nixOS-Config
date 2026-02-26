{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.zed-editor;

  ngram-en-pkg = inputs.nix-languagetool-ngram.packages.${pkgs.stdenv.hostPlatform.system}.ngrams-en;
  ngram-en = "${ngram-en-pkg}/share/languagetool/ngrams"; # LTeX expects the parent folder containing the 'en' folder
in
{
  options.myHome.homeApps.zed-editor = with lib; {
    enable = mkEnableOption "zed-editor";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

    home.packages = with pkgs; [
      nil # <-- language server
      nixfmt-rfc-style
      kdePackages.okular # Settings > Editor > Command: `zeditor %f:%l`
      ltex-ls-plus
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
        "ltex"
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
          ltex = {
            binary = {
              # You can keep this explicit path or remove it since ltex-ls-plus 
              # is already in your home.packages and should be in PATH
              path = "${pkgs.ltex-ls-plus}/bin/ltex-ls-plus"; 
            };
            settings = {
              ltex = {
                language = "en-US";
                additionalRules = {
                  enablePickyRules = true;
                  languageModel = "${ngram-en}";  # Your ngram path
                };
              };
            };
          };

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
            soft_wrap = "editor_width";
          };
          "Markdown" = {
            soft_wrap = "editor_width";
          };
          "Plain Text" = {
            soft_wrap = "editor_width";
          };
        };

      };
    };

  };
}
