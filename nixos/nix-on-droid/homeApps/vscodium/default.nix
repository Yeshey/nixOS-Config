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

      home.packages = with pkgs; [
        nixd
        nixfmt-rfc-style
        #nixd # nix language server 
        (vscode-with-extensions.override {
          vscode = unstable.vscodium.fhs;
          vscodeExtensions = with vscode-extensions; [
            # vscodevim.vim # this is later when you're a chad
            ms-vsliveshare.vsliveshare
            ms-azuretools.vscode-docker
            usernamehw.errorlens # Improve highlighting of errors, warnings and other language diagnostics.
            ritwickdey.liveserver # for html and css development
            # glenn2223.live-sass # not in nixpkgs
            yzhang.markdown-all-in-one # markdown
            formulahendry.code-runner
            james-yu.latex-workshop
            bungcip.better-toml # TOML language support
            rust-lang.rust-analyzer
            tamasfe.even-better-toml # Fully-featured TOML support
            eamodio.gitlens
            valentjn.vscode-ltex
            streetsidesoftware.code-spell-checker # spell checker
            
            bradlc.vscode-tailwindcss
            # arrterian.nix-env-selector # nix environment selector
            jnoortheen.nix-ide # not work?
            # you should try adding this one to have better nix code
            # b4dm4n.vscode-nixpkgs-fmt # for consistent nix code formatting (https://github.com/nix-community/nixpkgs-fmt)

            haskell.haskell

            # python
            # ms-python.python # Gives this error for now:
            #ERROR: Could not find a version that satisfies the requirement lsprotocol>=2022.0.0a9 (from jedi-language-server) (from versions: none)
            #ERROR: No matching distribution found for lsprotocol>=2022.0.0a9
            ms-python.vscode-pylance
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
          ]; # ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          #{
          #  name = "remote-ssh-edit";
          #  publisher = "ms-vscode-remote";
          #  version = "0.47.2";
          #  sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
          #}
          #];
        })
      ];

      # ====== Making VScodium settings writable ======
      # Allowing VScode to change settings on run time, see last response: https://github.com/nix-community/home-manager/issues/1800
      # VScodium is now free to write to its settings, but they will be overwritten when I run nixos rebuild
      # check also how he implemented in his repository: https://github.com/rgbatty/cauldron (nope!)
      home.activation.boforeCheckLinkTargets = {
        after = [ ];
        before = [ "checkLinkTargets" ];
        data = ''
          	userDir=/home/${config.myHome.user}/.config/VSCodium/User
          	rm -rf $userDir/settings.json

          	# as I changed the name to Visual Studio Code, I need to maintain VSC settings too
          	userDir2="/home/${config.myHome.user}/.config/Visual Studio Code/User"
          	rm -rf $userDir/settings.json
        '';
      };

      home.activation.afterWriteBoundary =
        let
          userSettings = vscUserSettings;
        in
        {
          after = [ "writeBoundary" ];
          before = [ ];
          data = ''
      if [ -d ~/.config/VSCodium/User ]; then
        userDir=$HOME/.config/VSCodium/User
        mkdir -p "$userDir"
        rm -rf $userDir/settings.json
        cat <<EOF > "$userDir/settings.json"
${userSettings}
EOF

        # for Code
        userDir3="$HOME/.config/Code/User"
        mkdir -p "$userDir3"
        rm -rf $userDir3/settings.json
        cat <<EOF > "$userDir3/settings.json"
${userSettings}
EOF

        # as I changed the name to Visual Studio Code, I need to maintain VSC settings too
        userDir2="$HOME/.config/Visual Studio Code/User"
        mkdir -p "$userDir2"
        rm -rf $userDir2/settings.json
        cat <<EOF > "$userDir2/settings.json"
${userSettings}
EOF

        # Also for .openvscode-server (I think you can put it here..?)
        userDir4="$HOME/.openvscode-server/data/Machine"
        mkdir -p "$userDir4"
        rm -rf $userDir4/settings.json
        cat <<EOF > "$userDir4/settings.json"
${userSettings}
EOF
      fi
    '';
        };
      # ====== ============================ ======    

      # for Code
      # userDir3="$HOME/.config/Code/User"
      # mkdir -p "$userDir3"
      # rm -rf $userDir3/settings.json
      # cat \
      #   ${(pkgs.formats.json {}).generate "blabla"
      #     userSettings} \
      #   > "$userDir3/settings.json"

      home.file = {
        # Change VSCodium to be able to use pylance (https://github.com/VSCodium/vscodium/pull/674#issuecomment-1137920704)
        ".config/VSCodium/product.json".source = builtins.toFile "product.json" ''
          {
            "nameShort": "Visual Studio Code",
            "nameLong": "Visual Studio Code",
          }
        '';
        # if you want to activate the MS extension store, add this as well:
        #"extensionsGallery": {
        #   "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
        #   "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
        #   "itemUrl": "https://marketplace.visualstudio.com/items"
        # }
      };
    };
}
