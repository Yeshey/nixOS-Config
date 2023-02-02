#
#  Common Home-Manager Configuration
#

{ config, lib, pkgs, user, location, host, ... }:

{
    # ====== Making VScode settings writable ======
    # Allowing VScode to change settings on run time, see last response: https://github.com/nix-community/home-manager/issues/1800
    # VScodium is now free to write to its settings, but they will be overwritten when I run nixos rebuild
    # check also how he implemented in his repository: https://github.com/rgbatty/cauldron (nope!)
    home.activation.boforeCheckLinkTargets = {
      after = [];
      before = [ "checkLinkTargets" ];
      data = ''
        userDir=/home/${user}/.config/VSCodium/User
        rm -rf $userDir/settings.json
      '';
    };

    home.activation.afterWriteBoundary = 
    let
        userSettings = import ./nixFiles/vscode-settings.nix;
    in
    {
      after = [ "writeBoundary" ];
      before = [];
      data = ''
        userDir=~/.config/VSCodium/User
        rm -rf $userDir/settings.json
        cat \
          ${(pkgs.formats.json {}).generate "blabla"
            userSettings} \
          > $userDir/settings.json
      '';
    };
    # ====== ============================ ======

    home = {
      username = "${user}";
      homeDirectory = "/home/${user}";

      packages = with pkgs; [
        github-desktop
        obs-studio
        qbittorrent
        yt-dlp # download youtube videos
        baobab
        gnome.cheese
        peek # doesn't work on wayland
        p3x-onenote # might be worth trying notekit(https://github.com/blackhole89/notekit) and Zettlr(https://github.com/Zettlr/Zettlr)
        signal-desktop
        lbry
        # etcher #insecure?

        # Browsers
        vivaldi

        # tmp
        teams
        skypeforlinux
        #staruml # UML diagrams
        jetbrains.clion # C++
        jetbrains.idea-community # java

        # Games
        osu-lazer
        # tetrio-desktop # runs horribly, better on the web
        prismlauncher # polymc # prismlauncher # for Minecraft
        heroic
        minetest
        the-powder-toy

        # Libreoffice
        libreoffice-qt
        hunspell
        hunspellDicts.uk_UA
 
        # SHELL
        oh-my-zsh
        zsh
        thefuck
        #autojump
      ];
    };

    nixpkgs.config.allowUnfree = true;
    # If I use the official launcher I can use this to set the .minecraft directory in my repository
    # nixpkgs.config.minecraft-fixed.commandLineArgs = "--workDir \"${location}/hosts/configFiles/.minecraft/\"";

    programs = {
      home-manager.enable = true;
      
      vscode = {
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

          haskell.haskell

          # python
          # ms-python.python # Gives this error for now:
          #ERROR: Could not find a version that satisfies the requirement lsprotocol>=2022.0.0a9 (from jedi-language-server) (from versions: none)
          #ERROR: No matching distribution found for lsprotocol>=2022.0.0a9
          ms-python.vscode-pylance

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
        userSettings = import ./nixFiles/vscode-settings.nix;
      };

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
          update = "sudo nixos-rebuild switch --flake ${location}#${host}"; # old: "sudo nixos-rebuild switch";
          upgrade = "trap \"cd ${location} && git checkout -- flake.lock\" INT ; sudo nixos-rebuild switch --flake ${location}#${host} --upgrade --update-input nixos-hardware --update-input home-manager --update-input nixpkgs || (cd ${location} && git checkout -- flake.lock)"; #--commit-lock-file #upgrade: upgrade NixOS to the latest version in your chosen channel";
          clean = "echo \"This will clean all generations, and optimise the store\" ; sudo sh -c 'nix-collect-garbage -d ; nix-store --optimise'";
          cp = "cp -i";                                   # Confirm before overwriting something
          df = "df -h";                                   # Human-readable sizes
          free = "free -m";                               # Show sizes in MB
          gitu = "git add . && git commit && git push";
          zshreload = "clear && zsh";
          zshconfig = "nano ~/.zshrc";
          # killall latte-dock && latte-dock & && kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell"
          re-kde = "nix-shell -p killall --command \"kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell\""; # Restart gui in KDE
          mount = "mount|column -t";                      # Pretty mount
          speedtest = "nix-shell -p python3 --command \"curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -\"";
          temperature = "watch \"nix-shell -p lm_sensors --command sensors | grep temp1 | awk '{print $2}' | sed 's/+//'\"";
          rvt = "nix-shell -p ffmpeg --command \"bash <(curl -s https://raw.githubusercontent.com/Yeshey/RecursiveVideoTranscoder/main/RecursiveVideoTranscoder.sh)\"";
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
        enableSyntaxHighlighting = true;
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

    # Syncthing shortcut, based on webapp manager created shortcut (https://github.com/linuxmint/webapp-manager)
    home.file.".local/share/applications/vivaldi-syncthing.desktop".source = builtins.toFile "vivaldi-syncthing.desktop" ''
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
    home.file.".local/share/applications/MSwhiteboard.desktop".source = builtins.toFile "MSwhiteboard.desktop" ''
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
    home.file.".stignore".source = builtins.toFile ".stignore" ''
!/.zsh_history
!/.bash_history
!/.python_history
// Ignore everything else:
*
    '';

    home.stateVersion = "22.11";
  }
