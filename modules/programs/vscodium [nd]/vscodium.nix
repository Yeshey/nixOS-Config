{ inputs, ... }:
{
  flake.modules.homeManager.vscodium =
    { pkgs, config, ... }:
    let
      ngram-en-pkg = inputs.nix-languagetool-ngram.packages.${pkgs.stdenv.hostPlatform.system}.ngrams-en;
      ngram-en = "${ngram-en-pkg}/share/languagetool/ngrams";
    in
    {
      config =
      let
        baseSettings = builtins.fromJSON (builtins.readFile ./VSCsettings.json);
        userSettings = baseSettings // {
          "ltex.ltex-ls.path" = "${pkgs.ltex-ls-plus}";
          "ltex.additionalRules.languageModel" = "${ngram-en}";
        };
      in
        {
          home.file."/home/${config.home.username}/.openvscode-server/data/Machine/settings.json" = {
            text = builtins.toJSON userSettings; # Converts the Nix set back to a JSON string
            force = true;
          };
          
          programs.vscode = {
            enable = true;
            mutableExtensionsDir = true;
            package = pkgs.vscodium;
            profiles.default = {
              userSettings = userSettings;
              extensions = with pkgs.vscode-extensions; [
                  mkhl.direnv 
                  jnoortheen.nix-ide
                  ms-azuretools.vscode-docker
                  usernamehw.errorlens
                  eamodio.gitlens
                  ritwickdey.liveserver
                  yzhang.markdown-all-in-one
                  james-yu.latex-workshop
                  rust-lang.rust-analyzer
                  tamasfe.even-better-toml
                  ltex-plus.vscode-ltex-plus
                  bradlc.vscode-tailwindcss
                  # python
                  ms-python.vscode-pylance
                  ms-python.python
                  ms-toolsai.jupyter

                  # java
                  redhat.java
                  vscjava.vscode-java-debug
                  vscjava.vscode-java-test

                  # C
                  llvm-vs-code-extensions.vscode-clangd
              ];
            };
          };

          home.packages = with pkgs; [
            nixd
            nixfmt-rfc-style
            ltex-ls-plus
          ];
        };
      };
}