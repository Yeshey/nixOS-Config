{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.myHome.homeApps.vscodium;
in
{
  imports = [
    # from https://github.com/nix-community/home-manager/issues/1800, to make vscode settings writable
    # Source: https://gist.github.com/piousdeer/b29c272eaeba398b864da6abf6cb5daa
    # Make vscode settings writable

    (import (builtins.fetchurl {
      url = "https://gist.githubusercontent.com/piousdeer/b29c272eaeba398b864da6abf6cb5daa/raw/41e569ba110eb6ebbb463a6b1f5d9fe4f9e82375/mutability.nix";
      sha256 = "4b5ca670c1ac865927e98ac5bf5c131eca46cc20abf0bd0612db955bfc979de8";
    }) { inherit config lib; })

    (import (builtins.fetchurl {
      url = "https://gist.githubusercontent.com/piousdeer/b29c272eaeba398b864da6abf6cb5daa/raw/41e569ba110eb6ebbb463a6b1f5d9fe4f9e82375/vscode.nix";
      sha256 = "fed877fa1eefd94bc4806641cea87138df78a47af89c7818ac5e76ebacbd025f";
    }) { inherit config lib pkgs; })
  
  ];

  options.myHome.homeApps.vscodium = with lib; {
    enable = mkEnableOption "vscodium";
  };

  config =
    let
      # VSC accepts normal json with comments
      vscUserSettings = builtins.readFile ./VSCsettings.json;
    in
    lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

      # Used this to find out what was being changed
      # nix-shell -p inotify-tools --run "stdbuf -oL inotifywait -m -r ~ --format '%w%f %e' -e modify -e create -e delete | tee /tmp/t.txt"
      home.persistence."/persistent" = {
        directories = [
          ".local/share/code-server/User"
          ".vscode-oss/extensions" 
        ];
      };

      #home.file."/home/${config.myHome.user}/.config/VSCodium/User/settings.json".source = ./VSCsettings.json;
      #home.file."/home/${config.myHome.user}/.config/Code/User/settings.json".source = ./VSCsettings.json;
      #home.file."/home/${config.myHome.user}/.config/Visual Studio Code/User/settings.json".source = ./VSCsettings.json;
      home.file."/home/${config.myHome.user}/.openvscode-server/data/Machine/settings.json" = {
        text = builtins.readFile ./VSCsettings.json;
        force = true;
        mutable = true;
      };
      
      programs.vscode = {
        enable = true;
        mutableExtensionsDir = true;
        package = pkgs.vscodium;
        profiles.default = {
          userSettings = builtins.fromJSON (builtins.readFile ./VSCsettings.json);
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
              redhat.vscode-xml # not installed??
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
      };

      home.packages = with pkgs; [
        nixd
        nixfmt-rfc-style
        #nixd # nix language server 
      ];

    };
}
