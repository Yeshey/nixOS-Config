{ inputs, ... }:
{
  flake.modules.homeManager.zed-editor-client =
    { pkgs, ... }:
    let
      ngram-en-pkg = inputs.nix-languagetool-ngram.packages.${pkgs.stdenv.hostPlatform.system}.ngrams-en;
      ngram-en = "${ngram-en-pkg}/share/languagetool/ngrams";
    in
    {
      home.packages = with pkgs; [
        nil
        nixfmt-rfc-style
        kdePackages.okular
        ltex-ls-plus
      ];

      programs.zed-editor = {
        enable = true;
        package = pkgs.unstable.zed-editor;
        installRemoteServer = true;

        extensions = [
          "nix"
          "toml"
          "rust"
          "latex"
          "react-typescript-snippets"
          "codebook"
          "git-firefly"
          "make"
          "ltex"
        ];

        userSettings = {
          hour_format = "hour24";
          load_direnv = "shell_hook";
          base_keymap = "VSCode";

          autosave = {
            after_delay = {
              milliseconds = 1000;
            };
          };

          lsp = {
            ltex = {
              binary = {
                path = "${pkgs.ltex-ls-plus}/bin/ltex-ls-plus";
              };
              settings = {
                ltex = {
                  language = "en-US";
                  additionalRules = {
                    enablePickyRules = true;
                    languageModel = "${ngram-en}";
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
          };

          languages = {
            "LaTeX" = { soft_wrap = "editor_width"; };
            "Markdown" = { soft_wrap = "editor_width"; };
            "Plain Text" = { soft_wrap = "editor_width"; };
          };
        };
      };
    };
}