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

    programs.zed-editor = {
      enable = true;
      extensions = [ "nix" "toml" "rust" "latex" "react-typescript-snippets" "react-typescript-snippets" ];
      userSettings = {
        hour_format = "hour24";
        # vim_mode = true;
        # Tell Zed to use direnv and direnv can use a flake.nix environment
        load_direnv = "shell_hook";
        base_keymap = "VSCode";
        
        # ---------- LaTeX ----------
        "lsp" = {
          "texlab" = {
            "settings" = {
              "texlab" = {
                "build" = {
                  "onSave" = true;               # compile when you save
                  "forwardSearchAfter" = true;   # jump to PDF after build
                  "executable" = "latexmk";
                  "args" = [
                    "-pdf"
                    "-synctex=1"
                    "-interaction=nonstopmode"
                    "-file-line-error"
                    "%f"
                  ];
                };
              };
            };
          };
        };
      };
    };

  };
}
