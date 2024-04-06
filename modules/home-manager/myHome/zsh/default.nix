{ lib, pkgs, ... }:

{
  options.myHome.zsh = with lib; {
    enable = mkEnableOption "zsh";
  };

  config = {

    /*
    programs.zsh = {
      enable = true;
      shellAliases = {
        vim = "nvim";
        # ls = "lsd -l --group-dirs first";
        #update = "sudo nixos-rebuild switch --flake ${location}#${host}"; # --impure # old: "sudo nixos-rebuild switch";
        #update-re = "sudo nixos-rebuild boot --flake ${location}#${host} --impure && reboot"; # old: "sudo nixos-rebuild switch";
        #upgrade = "trap \"cd ${location} && git checkout -- flake.lock\" INT ; sudo nixos-rebuild switch --flake ${location}#${host} --upgrade --update-input nixos-hardware --update-input nixos-nvidia-vgpu --update-input home-manager --update-input nixpkgs --impure || (cd ${location} && git checkout -- flake.lock)"; # --commit-lock-file #upgrade: upgrade NixOS to the latest version in your chosen channel";
        #upgrade-nixpkgs = "trap \"cd ${location} && git checkout -- flake.lock\" INT ; sudo nixos-rebuild switch --flake ${location}#${host} --upgrade --update-input nixpkgs --impure || (cd ${location} && git checkout -- flake.lock)";
        clean = "echo \"This will clean all generations, and optimise the store\" ; sudo sh -c 'nix-collect-garbage -d ; nix-store --optimise'";
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
        chtp = " curl cht.sh/python/\"$1\" ";           # alias to use cht.sh for python help
        chtc = " curl cht.sh/c/\"$1\" ";                # alias to use cht.sh for c help
        chtsharp = " curl cht.sh/csharp/\"$1\" ";           # alias to use cht.sh for c# help
        cht = " curl cht.sh/\"$1\" ";                   # alias to use cht.sh in general
      };
      #autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
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
        theme = "agnoster"; # robbyrussell # agnoster # frisk
      };
    };*/

    programs.zsh = {
      enable = true;
      history = {
        size = 10000;
      };
      shellAliases = {
        ll = "eza -l --icons=auto";
        la = "eza -la --icons=auto";
        ns = "sudo nixos-rebuild switch --flake .";
        hs = "home-manager switch --impure --flake .";
      };
      # bash
      initExtraBeforeCompInit = ''
        # Completion
        zstyle ':completion:*' menu yes select

        # Prompt
        source ${pkgs.spaceship-prompt}/lib/spaceship-prompt/spaceship.zsh
        autoload -U promptinit; promptinit
      '';
      # bash
      initExtra = ''
        source ${./kubectl.zsh}
        source ${./git.zsh}

        bindkey '^[[Z' reverse-menu-complete

        # Workaround for ZVM overwriting keybindings
        zvm_after_init_commands+=("bindkey '^[[A' history-substring-search-up")
        zvm_after_init_commands+=("bindkey '^[OA' history-substring-search-up")
        zvm_after_init_commands+=("bindkey '^[[B' history-substring-search-down")
        zvm_after_init_commands+=("bindkey '^[OB' history-substring-search-down")
      '';
      localVariables = {
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=13,underline";
        ZSH_AUTOSUGGEST_STRATEGY = [ "history" "completion" ];
        KEYTIMEOUT = 1;
        ZSHZ_CASE = "smart";
        ZSHZ_ECHO = 1;
      };
      enableAutosuggestions = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      enableVteIntegration = true;
      historySubstringSearch = {
        enable = true;
      };
      plugins = [
        {
          name = "nix-shell";
          src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
        }
        {
          name = "you-should-use";
          src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
        }
        #{ # TODO possibly reenable, also oh-my-zsh doesnt work? can't add the theme
        #  name = "zsh-vi-mode";
        #  src = "${pkgs.unstable.zsh-vi-mode}/share/zsh-vi-mode";
        #}
        {
          name = "zsh-z";
          src = "${pkgs.zsh-z}/share/zsh-z";
        }
      ];
    };
    home.file.".config/spaceship.zsh".source = ./spaceship.zsh;
  };
}
