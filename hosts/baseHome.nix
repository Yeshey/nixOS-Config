#
#  Common Home-Manager Configuration
#

{ config, lib, pkgs, user, location, host, ... }:

let
  # the latex code: https://stackoverflow.com/questions/56743092/modifying-settings-json-in-vscode-to-add-shell-escape-flag-to-pdflatex-in-latex
  # You need to add this code here as well but you don't know how, so latex works with svgs
  vscUserSettings = builtins.fromJSON (builtins.readFile ./configFiles/VSCsettings.json);
in
{

    # ====== Making VScodium settings writable ======
    # Allowing VScode to change settings on run time, see last response: https://github.com/nix-community/home-manager/issues/1800
    # VScodium is now free to write to its settings, but they will be overwritten when I run nixos rebuild
    # check also how he implemented in his repository: https://github.com/rgbatty/cauldron (nope!)
    home.activation.boforeCheckLinkTargets = {
      after = [];
      before = [ "checkLinkTargets" ];
      data = ''
        userDir=/home/${user}/.config/VSCodium/User
        rm -rf $userDir/settings.json

        # as I changed the name to Visual Studio Code, I need to maintain VSC settings too
        userDir2="/home/${user}/.config/Visual Studio Code/User"
        rm -rf $userDir/settings.json
      '';
    };

    home.activation.afterWriteBoundary = 
    let
        userSettings = vscUserSettings;
    in
    {
      after = [ "writeBoundary" ];
      before = [];
      data = ''
        if [ -d ~/.config/VSCodium/User ]; then
          userDir=$HOME/.config/VSCodium/User
          mkdir -p "$userDir"
          rm -rf $userDir/settings.json
          cat \
            ${(pkgs.formats.json {}).generate "blabla"
              userSettings} \
            > "$userDir/settings.json"

          # for Code
          userDir3="$HOME/.config/Code/User"
          mkdir -p "$userDir3"
          rm -rf $userDir3/settings.json
          cat \
            ${(pkgs.formats.json {}).generate "blabla"
              userSettings} \
            > "$userDir3/settings.json"

          # as I changed the name to Visual Studio Code, I need to maintain VSC settings too
          userDir2="$HOME/.config/Visual Studio Code/User"
          mkdir -p "$userDir2"
          rm -rf $userDir2/settings.json
          cat \
            ${(pkgs.formats.json {}).generate "blabla"
              userSettings} \
            > "$userDir2/settings.json"

          # Also for .openvscode-server (I think you can put it here..?)
          userDir4="$HOME/.openvscode-server/data/Machine"
          mkdir -p "$userDir4"
          rm -rf $userDir4/settings.json
          cat \
            ${(pkgs.formats.json {}).generate "blabla"
              userSettings} \
            > "$userDir4/settings.json"
        fi
      '';
    };
    # ====== ============================ ======    

/*
          # for Code
          # userDir3="$HOME/.config/Code/User"
          # mkdir -p "$userDir3"
          # rm -rf $userDir3/settings.json
          # cat \
          #   ${(pkgs.formats.json {}).generate "blabla"
          #     userSettings} \
          #   > "$userDir3/settings.json"
*/

    home = {
      username = "${user}";
      homeDirectory = "/home/${user}";
    };

    nixpkgs.config.allowUnfree = true;
    # If I use the official launcher I can use this to set the .minecraft directory in my repository
    # nixpkgs.config.minecraft-fixed.commandLineArgs = "--workDir \"${location}/hosts/configFiles/.minecraft/\"";

    programs = {
      home-manager.enable = true;
      
      # This method isn't installing extensions..? Installing in baseConfig
      /* vscode = {
        enable = true;
        package = pkgs.vscodium;
        #haskell = { ?
          #enable = true;
          #hie = {
            #enable = true;
            #executablePath = "${pkgs.hies}/bin/hie-wrapper";
          #};
        #};
        extensions = with pkgs.vscode-extensions; [
          # vscodevim.vim # this is later when you're a chad
          ms-vsliveshare.vsliveshare
          bbenoist.nix # nix language highlighting
          ms-azuretools.vscode-docker
          usernamehw.errorlens # Improve highlighting of errors, warnings and other language diagnostics.
          ritwickdey.liveserver # for html and css development
          # glenn2223.live-sass # not in nixpkgs
          yzhang.markdown-all-in-one # markdown
          formulahendry.code-runner
          james-yu.latex-workshop
          bungcip.better-toml # TOML language support
          matklad.rust-analyzer
          arrterian.nix-env-selector # nix environment selector
          tamasfe.even-better-toml # Fully-featured TOML support

          haskell.haskell

          # python
          # ms-python.python # Gives this error for now:
          #ERROR: Could not find a version that satisfies the requirement lsprotocol>=2022.0.0a9 (from jedi-language-server) (from versions: none)
          #ERROR: No matching distribution found for lsprotocol>=2022.0.0a9
          ms-python.vscode-pylance
          ms-python.python

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

          # remote extension pack
          # jeanp413.open-remote-ssh # not in nixpkgs install manually, and see extension page to add one more thing to configuration for it to work
          # ms-vscode-remote.remote-ssh # doesn't work in vscodium
        ];
        userSettings = vscUserSettings;
      }; */

      # Github Desktop is complaining about .git config being read only
      git = {
        enable = true;
        userEmail = "yesheysangpo@hotmail.com";
        userName = "Yeshey";
      };

      zsh={
        enable = true;
        shellAliases = {
          vim = "nvim";
          # ls = "lsd -l --group-dirs first";
          update = "sudo nixos-rebuild switch --flake ${location}#${host} --impure"; # old: "sudo nixos-rebuild switch";
          update-re = "sudo nixos-rebuild boot --flake ${location}#${host} --impure && reboot"; # old: "sudo nixos-rebuild switch";
          upgrade = "trap \"cd ${location} && git checkout -- flake.lock\" INT ; sudo nixos-rebuild switch --flake ${location}#${host} --upgrade --update-input nixos-hardware --update-input nixos-nvidia-vgpu --update-input home-manager --update-input nixpkgs --impure || (cd ${location} && git checkout -- flake.lock)"; #--commit-lock-file #upgrade: upgrade NixOS to the latest version in your chosen channel";
          clean = "echo \"This will clean all generations, and optimise the store\" ; sudo sh -c 'nix-collect-garbage -d ; nix-store --optimise'";
          #"sudo dolphin" = "sudo SUDO_USER= dolphin";
          cp = "cp -i";                                   # Confirm before overwriting something
          df = "df -h";                                   # Human-readable sizes
          free = "free -m";                               # Show sizes in MB
          gitu = "git add . && git commit && git push";
          zshreload = "clear && zsh";
          zshconfig = "nano ~/.zshrc";
          # killall latte-dock && latte-dock & && kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell"
          re-kde = "nix-shell -p killall --command \"kquitapp5 plasmashell || killall plasmashell ; kstart5 plasmashell\""; # Restart gui in KDE
          mount = "mount|column -t";                      # Pretty mount
          speedtest = "nix-shell -p python3 --command \"curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -\"";
          temperature = "watch \"nix-shell -p lm_sensors --command sensors | grep temp1 | awk '{print $2}' | sed 's/+//'\"";
          rvt = "nix-shell -p ffmpeg --command \"bash <(curl -s https://raw.githubusercontent.com/Yeshey/RecursiveVideoTranscoder/main/RecursiveVideoTranscoder.sh)\"";
          win10-vm = "sh <(curl -s https://raw.githubusercontent.com/Yeshey/nixos-nvidia-vgpu_nixOS/master/run-vm.sh)";
          ping = "ping -c 5";                             # Control output of ping
          fastping = "ping -c 100 -s 1";
          ports = "netstat -tulanp";                      # Show Open ports
          l="ls -l";
          la="ls -a";
          lla="ls -la";
          lt="ls --tree";
          grep="grep --color=auto";
          egrep="egrep --color=auto";
          fgrep="fgrep --color=auto";
          diff="colordiff";
          dir="dir --color=auto";
          vdir="vdir --color=auto";
          week = "
            now=$(date '+%V %B %Y');
            echo \"Week Date:\" $now
          ";
          myip = "  
            echo \"Your external IP address is:\"
            curl -w '\n' https://ipinfo.io/ip
          ";
          chtp = " curl cht.sh/python/\"$1\" ";           # lias to use cht.sh for python help
          chtc = " curl cht.sh/c/\"$1\" ";                # alias to use cht.sh for c help
          chtsharp = " curl cht.sh/csharp/\"$1\" ";           # alias to use cht.sh for c# help
          cht = " curl cht.sh/\"$1\" ";                   # alias to use cht.sh in general
        };
        enableAutosuggestions = true;
  #      autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        enableCompletion = true;
        history = {
          size = 100000;
          # path = "${location}/hosts/configFiles/.zsh_history"; # Auto save history to the file in this repository
        };
        # histSize = 100000;
        oh-my-zsh = {
          enable = true;
          plugins = [ "git" 
                      "colored-man-pages" 
                      "alias-finder" 
                      "command-not-found" 
                      #"autojump" 
                      "urltools" 
                      "bgnotify"];
          theme = "frisk"; # robbyrussell # agnoster
        };
      };

    };

  home = {
    packages = with pkgs; [
      # SHELL
      oh-my-zsh
      zsh
      thefuck
      #autojump
    ];
  };
    
    # My home files 
    home.file = /* let
      autostartPrograms = [ pkgs.discord pkgs.premid pkgs.anydesk ];
    in builtins.listToAttrs (map
          # Startup applications with home manager
          # https://github.com/nix-community/home-manager/issues/3447
          (pkg:
            {
              name = ".config/autostart/" + pkg.pname + ".desktop";
              value =
                if pkg ? desktopItem then {
                  # Application has a desktopItem entry. 
                  # Assume that it was made with makeDesktopEntry, which exposes a
                  # text attribute with the contents of the .desktop file
                  text = pkg.desktopItem.text;
                } else {
                  # Application does *not* have a desktopItem entry. Try to find a
                  # matching .desktop name in /share/apaplications
                  source = (pkg + "/share/applications/" + pkg.pname + ".desktop");
                };
            })
          autostartPrograms)
          // */
          {
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

      # Syncthing shortcut, based on webapp manager created shortcut (https://github.com/linuxmint/webapp-manager)
      ".local/share/applications/vivaldi-syncthing.desktop".source = builtins.toFile "vivaldi-syncthing.desktop" ''
[Desktop Entry]
Version=1.0
Name=Syncthing
Comment=Web App
Exec=vivaldi --app="http://127.0.0.1:8384#" --class=WebApp-Syncthingvivaldi5519 --user-data-dir=/home/yeshey/.local/share/ice/profiles/Syncthingvivaldi5519
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=webapp-manager
Categories=GTK;WebApps;
MimeType=text/html;text/xml;application/xhtml_xml;
StartupWMClass=WebApp-Syncthingvivaldi5519
StartupNotify=true
X-WebApp-Browser=Vivaldi
X-WebApp-URL=http://127.0.0.1:8384#
X-WebApp-CustomParameters=
X-WebApp-Navbar=false
X-WebApp-PrivateWindow=false
X-WebApp-Isolated=true
          '';

      # MS WhiteBoard, based on webapp manager created shortcut (https://github.com/linuxmint/webapp-manager)
      ".local/share/applications/MSwhiteboard.desktop".source = builtins.toFile "MSwhiteboard.desktop" ''
[Desktop Entry]
Version=1.0
Name=MS WhiteBoard
Comment=Web App
Exec=vivaldi --app="https://whiteboard.office.com" --class=WebApp-MSwhiteboard2348 --user-data-dir=/home/yeshey/.local/share/ice/profiles/MSwhiteboard2348
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=webapp-manager
Categories=GTK;WebApps;
MimeType=text/html;text/xml;application/xhtml_xml;
StartupWMClass=WebApp-MSwhiteboard2348
StartupNotify=true
X-WebApp-Browser=Vivaldi
X-WebApp-URL=https://whiteboard.office.com
X-WebApp-CustomParameters=
X-WebApp-Navbar=false
X-WebApp-PrivateWindow=false
X-WebApp-Isolated=true
          '';

      # Make a symlinks for Syncthing Ignore file:
      ".stignore".source = builtins.toFile ".stignore" ''
!/.zsh_history
!/.bash_history
!/.python_history
// Ignore everything else:
*
          '';

      # So it doesn't sync for example the mouse sensitivity between devices
      ".local/share/osu/.stignore".source = builtins.toFile ".stignore" ''
// Don't ignore these files...
!/files
!/screenshots
!/collection.db
!/client.realm

// Ignore everything else in osu folder
*
        '';

      # So it doesn't sync for example the mouse sensitivity between devices
      ".local/share/Mindustry/.stignore".source = builtins.toFile ".stignore" ''
// Don't ignore these files...

// Ignore everything else in Mindustry folder
// *
        '';

      # For discord to start correctly (from nixOS wiki discord page)
      ".config/discord/settings.json".source = builtins.toFile "MSwhiteboard.desktop" ''
{
  "IS_MAXIMIZED": false,
  "IS_MINIMIZED": true,
  "SKIP_HOST_UPDATE": true,
  "WINDOW_BOUNDS": {
    "x": 173,
    "y": 68,
    "width": 1630,
    "height": 799
  }
}
          '';
    };

    home.stateVersion = "22.11";
  }
