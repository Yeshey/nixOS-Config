{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.vscodium;
in
{
  options.myHome.homeApps.vscodium = with lib; {
    enable = mkEnableOption "vscodium";
  };

  config =
    let
      # VSC accepts normal json with comments
      vscUserSettings = builtins.readFile ./VSCsettings.json;
    in
    lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

    programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;
      package = pkgs.vscodium;
      userSettings = lib.mkForce ./VSCsettings.json;
      extensions = with pkgs.vscode-extensions; [
          # vscodevim.vim # this is later when you're a chad
          ms-vsliveshare.vsliveshare
          ms-azuretools.vscode-docker
          usernamehw.errorlens # Improve highlighting of errors, warnings and other language diagnostics.
          ritwickdey.liveserver # for html and css development
          # glenn2223.live-sass # not in nixpkgs
          yzhang.markdown-all-in-one # markdown
          formulahendry.code-runner
          james-yu.latex-workshop
          tamasfe.even-better-toml # TOML language support
          rust-lang.rust-analyzer
          tamasfe.even-better-toml # Fully-featured TOML support
          eamodio.gitlens
          valentjn.vscode-ltex
          streetsidesoftware.code-spell-checker # spell checker
          
          bradlc.vscode-tailwindcss # tailwindcss
          # redhat.vscode-xml # not installed??
          # arrterian.nix-env-selector # nix environment selector
          mkhl.direnv # direnv (the good one!)
          jnoortheen.nix-ide # not work?
          # you should try adding this one to have better nix code
          # b4dm4n.vscode-nixpkgs-fmt # for consistent nix code formatting (https://github.com/nix-community/nixpkgs-fmt)

          haskell.haskell

          # python
          # ms-python.python # Gives this error for now:
          #ERROR: Could not find a version that satisfies the requirement lsprotocol>=2022.0.0a9 (from jedi-language-server) (from versions: none)
          #ERROR: No matching distribution found for lsprotocol>=2022.0.0a9
          ms-python.vscode-pylance
          ms-python.python
          ms-toolsai.jupyter
          # ms-python.python # Causing an error now

          # java
          redhat.java
          #search for extension pack for java
          vscjava.vscode-java-debug
          # vscjava.vscode-java-dependency
          # vscjava.vscode-java-pack
          vscjava.vscode-java-test
          # vscjava.vscode-maven

          # C
          llvm-vs-code-extensions.vscode-clangd

          ms-vscode-remote.remote-ssh
      ];
    };


      home.packages = with pkgs; [
        nixd
        nixfmt-rfc-style
      ];
    };
}
