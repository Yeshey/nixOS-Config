{ config, lib, pkgs, inputs, user, location, host, dataStoragePath, ... }:

{

  #     _____           _                    _____             __ _        (ASCII art: https://patorjk.com/software/taag/#p=display&f=Big&t=System%20Config)
  #    / ____|         | |                  / ____|           / _(_)      
  #   | (___  _   _ ___| |_ ___ _ __ ___   | |     ___  _ __ | |_ _  __ _ 
  #    \___ \| | | / __| __/ _ \ '_ ` _ \  | |    / _ \| '_ \|  _| |/ _` |
  #    ____) | |_| \__ \ ||  __/ | | | | | | |___| (_) | | | | | | | (_| |
  #   |_____/ \__, |___/\__\___|_| |_| |_|  \_____\___/|_| |_|_| |_|\__, |
  #            __/ |                                                 __/ |
  #           |___/                                                 |___/ 

  imports = [
    (import ./configFiles/tmp.nix)
    (import ./configFiles/syncthing.nix)
    # (import ./configFiles/non-serverConfiguration.nix)
  ];

  #     ___            __  (ASCII art: https://patorjk.com/software/taag/#p=display&f=Small%20Slant&t=Boot)
  #    / _ )___  ___  / /_
  #   / _  / _ \/ _ \/ __/
  #  /____/\___/\___/\__/                      

  #    -- grub --
  boot.tmp.cleanOnBoot = true; # delete all files in /tmp during boot.
  
  #     ___          __   __              ____         _                              __ 
  #    / _ \___ ___ / /__/ /____  ___    / __/__ _  __(_)______  ___  __ _  ___ ___  / /_
  #   / // / -_|_-</  '_/ __/ _ \/ _ \  / _// _ \ |/ / / __/ _ \/ _ \/  ' \/ -_) _ \/ __/
  #  /____/\__/___/_/\_\\__/\___/ .__/ /___/_//_/___/_/_/  \___/_//_/_/_/_/\__/_//_/\__/ 
  #                            /_/                                                       

  # Configure keymap in X11
  services.xserver = {
    layout = "pt";
    xkbVariant = "";
  };

  #    __  __              
  #   / / / /__ ___ _______
  #  / /_/ (_-</ -_) __(_-<
  #  \____/___/\__/_/ /___/

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true; # forward graphical interfaces through SSH
      PermitRootLogin = "yes"; # to let surface and Laptop connect to builds for the surface (https://github.com/NixOS/nixpkgs/issues/20718)
    };
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [ 
      # ssh public key of my_identity key
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop"
    ];
  };
  users.users.${user} = {
    isNormalUser = true;
    description = "Yeshey";
    extraGroups = [ "networkmanager" "wheel" "dialout" "docker" "adbusers" "libvirtd" "surface-control" "audio"]; # libvirtd - For android-studio
    packages = with pkgs; [
    #  thunderbird
    ];
    openssh.authorizedKeys.keys = [ 
      # ssh public key of my_identity key
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop"
    ];

    # needed to make home-manager zsh work with gdm
    shell = pkgs.zsh;
    useDefaultShell = false;
  };
  users.defaultUserShell = pkgs.zsh;

  # needed to make home-manager zsh work with gdm (https://www.reddit.com/r/NixOS/comments/ocimef/users_not_showing_up_in_gnome/)
  environment.pathsToLink = [ "/share/zsh" ];
  environment.shells = [ pkgs.zsh ];
  
  environment.sessionVariables = rec {
    CHROME_EXECUTABLE  = "\$(whereis brave | cut -d \" \" -f2)"; # needed for flutter, can remove later
    # you need to talso make a symlink to your dart sdk in your home folder with something like: ln -s /nix/store/xbq4nb97scigamd9kf2kdl7m1kr0w6m4-flutter-3.3.8/bin/cache/dart-sdk/ /home/yeshey/.cache/flutter/dart-sdk
    LD_LIBRARY_PATH="${pkgs.libepoxy}/lib"; # trying to make flutter work, can remove later
  };

  #      __                 __                            ____     
  #   __/ /_  ___ __ _____ / /____ __ _    _______  ___  / _(_)__ _
  #  /_  __/ (_-</ // (_-</ __/ -_)  ' \  / __/ _ \/ _ \/ _/ / _ `/
  #   /_/   /___/\_, /___/\__/\__/_/_/_/  \__/\___/_//_/_//_/\_, / 
  #             /___/                                       /___/

  # Configure console keymap
  console.keyMap = "pt-latin1";

  # Enable networking
  networking.hostName = "nixOS-${host}"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.resolvconf.dnsExtensionMechanism = false; # fixes internet connectivity problems with some sites (https://discourse.nixos.org/t/domain-name-resolve-problem/885/2)nvidia
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # DNS server was not working (https://unix.stackexchange.com/questions/510940/how-can-i-set-a-custom-dns-server-within-nixos) (maybe should put in general config?)
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" "9.9.9.9" ];

  # needed to access coimbra-dev raspberrypi
  systemd.network.wait-online.enable = false;
  networking.useNetworkd = true;

  #networking.useDHCP = false;
  #networking.useHostResolvConf = false;
  #networking.firewall.enable = false;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.utf8";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

/*
  # Auto Upgrade
  system.autoUpgrade = {
    enable = true;
    # dates = "23:01";
    flake = "${location}#${host}"; # my flake online uri is for example github:yeshey/nixos-config#laptop
    flags = [
      # "--upgrade --option fallback false --update-input nixos-hardware --update-input home-manager --update-input nixpkgs || (cd ${location} && git checkout --flake.lock)"

      # "--upgrade" (seems to be redundant) # upgrade NixOS to the latest version in your chosen channel
      # "--option fallback false" # fallback false should force it to use pre-built packages (https://github.com/NixOS/nixpkgs/issues/77971)
      # "--update-input nixos-hardware --update-input home-manager --update-input nixpkgs" # To update all the packages
      # "--commit-lock-file" # commit the new lock file with git
      # || cd ${location} && git checkout -- flake.lock '' # reverts the changes to flake.lock if things went south (doesn't work because the commands in this list they aren't placed in this order in the end)
    ];
    allowReboot = false; # set to false
  };
  systemd.services.nixos-upgrade.serviceConfig = let
    cfg = config.services.nixos-upgrade;
  in {
    # you can follow the service real time with journalctl -f -u nixos-upgrade.service
    # Also worth noting that these only apply to the physical RAM used,
    # they do not include swap space used. 
    # (There is a separate MemorySwapMax setting, but no MemorySwapHigh, it seems.)
    # https://unix.stackexchange.com/questions/436791/limit-total-memory-usage-for-multiple-instances-of-systemd-service
    MemoryHigh = [ "500M" ];
    MemoryMax = [ "2048M" ];

    # https://unix.stackexchange.com/questions/494843/how-to-limit-a-systemd-service-to-play-nice-with-the-cpu
    CPUWeight = [ "20" ];
    CPUQuota = [ "85%" ];
    IOWeight = [ "20" ];
    # this doesn't work yet (https://unix.stackexchange.com/questions/441575/proper-way-to-use-onfailure-in-systemd)
    ExecStopPost= [ "sh -c 'if [ \"$$SERVICE_RESULT\" != \"success\" ]; then cd ${location} && git checkout -- flake.lock; fi'" ];
  };
*/

  # Garbage Collect
  nix = let
    age.secrets.nix-access-tokens-github.file = "${location}/secrets/root.nix-access-tokens-github.age";
  in {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ]; # "ca-derivations"
      trusted-users = [ "root" "yeshey" "@wheel" ];

      #substituters = [ "https://numtide.cachix.org" "https://cache.nixos.org" ];
      #trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];
      # substituters = [ "https://cache.nixos.org/" "https://nixcache.reflex-frp.org" "https://cache.iog.io" "https://digitallyinduced.cachix.org" "https://ghc-nix.cachix.org" "https://ic-hs-test.cachix.org" "https://kaleidogen.cachix.org" "https://static-haskell-nix.cachix.org" "https://tttool.cachix.org" "https://cache.nixos.org/" "https://numtide.cachix.org" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
    extraOptions = ''preallocate-contents = false''; # for compression to work with btrfs (https://github.com/NixOS/nix/issues/3550) ...?
  };

  #    ____             _               ____      ___                                 
  #   / __/__ _____  __(_)______ ___   / __/___  / _ \_______  ___ ________ ___ _  ___
  #  _\ \/ -_) __/ |/ / / __/ -_|_-<   > _/_ _/ / ___/ __/ _ \/ _ `/ __/ _ `/  ' \(_-<
  # /___/\__/_/  |___/_/\__/\__/___/  |_____/  /_/  /_/  \___/\_, /_/  \_,_/_/_/_/___/
  #                                                          /___/                                                                   

  programs = {
    #firejail.enable = true; # so you can start apps in a sandbox?

    ssh = {
      startAgent = true;
      forwardX11 = true;
    };

    # general terminal shell config for all users
    zsh = {
      enable = true;
      shellAliases = {
        vim = "nvim";
        # ls = "lsd -l --group-dirs first";
        update = "sudo nixos-rebuild switch --flake ${location}#${host}"; # --impure # old: "sudo nixos-rebuild switch";
        update-re = "sudo nixos-rebuild boot --flake ${location}#${host} --impure && reboot"; # old: "sudo nixos-rebuild switch";
        upgrade = "trap \"cd ${location} && git checkout -- flake.lock\" INT ; sudo nixos-rebuild switch --flake ${location}#${host} --upgrade --update-input nixos-hardware --update-input nixos-nvidia-vgpu --update-input home-manager --update-input nixpkgs --impure || (cd ${location} && git checkout -- flake.lock)"; /*--commit-lock-file*/ #upgrade: upgrade NixOS to the latest version in your chosen channel";
        upgrade-nixpkgs = "trap \"cd ${location} && git checkout -- flake.lock\" INT ; sudo nixos-rebuild switch --flake ${location}#${host} --upgrade --update-input nixpkgs --impure || (cd ${location} && git checkout -- flake.lock)";
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
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      histSize = 100000;
      ohMyZsh = {
        enable = true;
        plugins = [ "git" 
                    "colored-man-pages" 
                    "alias-finder" 
                    "command-not-found" 
                    #"autojump" 
                    "urltools" 
                    "bgnotify"];
      };        theme = "agnoster"; # robbyrussell # agnoster # frisk
    };
  };

  #    ___           __                   
  #   / _ \___ _____/ /_____ ____ ____ ___
  #  / ___/ _ `/ __/  '_/ _ `/ _ `/ -_|_-<
  # /_/   \_,_/\__/_/\_\\_,_/\_, /\__/___/
  #                         /___/         

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    vivaldi = {
      proprietaryCodecs = true;
      enableWideVine = true;
      # https://forum.vivaldi.net/topic/62354/hardware-accelerated-video-encode/20 # in chrome its enabled by default, why not vivaldi
      # commandLineArgs = "--use-gl=desktop --enable-features=VaapiVideoDecoder --disable-features=UseOzonePlatform" ;  # wtf doesnt work?
    };
    #permittedInsecurePackages = [
    #    "openssl-1.1.1v" # Needed for now in 23.05?
    #];
    # allowUnsupportedSystem = true;
    # contentAddressedByDefault = true; # for the experimental feature "ca-derivations" # https://discourse.nixos.org/t/content-addressed-nix-call-for-testers/12881
  };

  environment.systemPackages = with pkgs; [
    vim # The Nano editor is installed by default.
    neovim
    htop
    tmux
    git
    wget
    tree
    unzip
    unrar # also to extract .rar with ark in KDE # unrar x Lab5.rar
    bat
    btop
    tldr

    xwaylandvideobridge

    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
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
          eamodio.gitlens
          valentjn.vscode-ltex
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

      ]; #++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        #{
        #  name = "remote-ssh-edit";
        #  publisher = "ms-vscode-remote";
        #  version = "0.47.2";
        #  sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        #}
      #];
    })
  ];

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
