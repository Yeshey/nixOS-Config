#
#  Common Home-Manager Configuration
#

{ config, lib, pkgs, user, location, ... }:

{ 

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    packages = with pkgs; [
      github-desktop
      obs-studio
      qbittorrent
      yt-dlp # download youtube videos

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

  programs = {
    home-manager.enable = true;
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
        re-kde = "killall latte-dock && latte-dock & && kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell"; # Restart gui in KDE
        mount = "mount|column -t";                      # Pretty mount
        speedtest = "nix-shell -p python3 --command \"curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -\"";
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

  home.stateVersion = "22.11";
}
