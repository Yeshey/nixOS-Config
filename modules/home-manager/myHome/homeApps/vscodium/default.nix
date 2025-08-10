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
    # Source: https://gist.github.com/js6pak/d17a317de6a76ba9dac0d110adc651ed
    # Make vscode settings writable

    (import (builtins.fetchurl {
      url = "https://gist.githubusercontent.com/js6pak/d17a317de6a76ba9dac0d110adc651ed/raw/309b3d066d00ca59e0342c458ceb2d10b1c5f6e9/mutability.nix";
      sha256 = "sha256:1s4xjzy5p5fv283bvw5b4364djhy2dfbzicax4kmk1mcq5qacp2b";
    }) { inherit config lib; })

    (import (builtins.fetchurl {
      url = "https://gist.githubusercontent.com/js6pak/d17a317de6a76ba9dac0d110adc651ed/raw/309b3d066d00ca59e0342c458ceb2d10b1c5f6e9/vscode.nix";
      sha256 = "sha256:0mb2fn4d61wrscv0nwi3hyflgs3gg8gaw78xayj97n5mslbj7sh9";
    }) { inherit config lib pkgs; }) #
  
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
      home.persistence."/persistent" = lib.mkIf config.myHome.impermanence.enable {
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
