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
    ];

    programs.zathura = {
      enable = true;
      package = pkgs.zathura;
      options = {
        synctex = true;
        synctex-editor-command = "${pkgs.zed-editor}/bin/zeditor %{input}:%{line}"; # Inverse search
      };
    };

    programs.zed-editor = {
      enable = true;
      extensions = [
        "nix"
        "toml"
        "rust"
        "latex"
        "react-typescript-snippets"
      ];
      userSettings = {
        hour_format = "hour24";
        # vim_mode = true;
        # Tell Zed to use direnv and direnv can use a flake.nix environment
        load_direnv = "shell_hook";
        base_keymap = "VSCode";

        # ---------- LaTeX ----------
        # LaTeX
        lsp.texlab = {
          settings = {
            texlab = {
              build = {
                onSave = true;
                forwardSearchAfter = true;
                executable = "${pkgs.texlive.combined.scheme-full}/bin/latexmk";
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
                executable = "zathura";
                args = [
                  "--synctex-forward"
                  "%l:1:%f"
                  "%p"
                ];
              };
            };
          };
        };

      };
    };

  };
}
