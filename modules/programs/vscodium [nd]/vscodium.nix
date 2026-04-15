{ inputs, ... }:
{
  flake.modules.nixos.vscodium =
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.vscodium
      ];
    }; 

  flake.modules.homeManager.vscodium =
    { pkgs, config, ... }:
    let
      ngram-en-pkg = inputs.nix-languagetool-ngram.packages.${pkgs.stdenv.hostPlatform.system}.ngrams-en;
      ngram-en = "${ngram-en-pkg}/share/languagetool/ngrams";
      # Define my stable path directory for Nix dependencies
      nixDepsDir = ".local/share/vscodium-nix-deps";
    in
    {
      config = {
        home.file."${nixDepsDir}/ltex-ls-plus".source = pkgs.ltex-ls-plus;
        home.file."${nixDepsDir}/ngram-en".source = ngram-en;

        programs.vscode = {
          enable = true;
          package = pkgs.vscodium;
          profiles.default = {
            # Has to be a full path and a string to prevent it to be picked up by nix and coppied to the readonly nix store.
            userSettings = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.setup/modules/programs/vscodium [nd]/VSCsettings.json";

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
                ms-python.vscode-pylance
                ms-python.python
                ms-toolsai.jupyter
                redhat.java
                vscjava.vscode-java-debug
                vscjava.vscode-java-test
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