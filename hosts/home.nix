#
#  Common Home-Manager Configuration
#

{ config, lib, pkgs, user, location, ... }:

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
        p3x-onenote

        # Browsers
        vivaldi

        # tmp
        teams
        staruml # UML diagrams
        jetbrains.clion # C++
        jetbrains.idea-community # java

        # Games
        osu-lazer
        prismlauncher # polymc # prismlauncher # for Minecraft
        heroic

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

    xdg.desktopEntries = {
      staruml = {
        name = "staruml";
        exec = "${pkgs.staruml}/bin/staruml %U --no-sandbox";
        icon = "staruml";
        categories = [ "Development" ];
      };
      #vivaldi = {
      #  name = "Vivaldi";
      #  exec = "${pkgs.vivaldi}/bin/vivaldi %U --enable-features=UseOzonePlatform --ozone-platform=wayland";
      #  icon = "vivaldi";
      #  categories = [ "Network" "WebBrowser" ];
      #};
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

          # Haskell ?
          # haskell.haskell

          # python
          ms-python.python
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
          update = "cd ${location} && sudo nixos-rebuild switch --flake .#laptop"; #old: "sudo nixos-rebuild switch";
          upgrade = "cd ${location} && sudo nixos-rebuild switch --flake .#laptop --upgrade"; #old: upgrade = "sudo nixos-rebuild switch --upgrade";
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
          clean = "echo \"This will clean all generations, and optimise the store\" ; sudo sh -c 'nix-collect-garbage -d ; nix-store --optimise'";
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
          path = "${location}/hosts/configFiles/.zsh_history"; # Auto save history to the file in this repository
        };
        # histSize = 100000;
        oh-my-zsh = {
          enable = true;
          plugins = [ "git" 
                      "thefuck" 
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

    # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
    home.file.".local/share/osu/storage.ini".source = builtins.toFile "storage.ini" ''
  FullPath = ${location}/hosts/configFiles/osu-lazer/
    '';

    home.stateVersion = "22.11";
  }
