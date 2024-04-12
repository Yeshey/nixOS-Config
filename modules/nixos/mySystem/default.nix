{ inputs, outputs, config, lib, pkgs, ... }:

let
  cfg = config.mySystem;
  # Extra caches to pull from (taken from https://discourse.nixos.org/t/package-building-in-flake-despite-provided-substitutes/18107)
  # Shouldn't need to set nixConfig.extra-substituters like this (https://nixos.org/manual/nix/stable/command-ref/conf-file#file-format)
  substituters = {
    cachenixosorg = {
      url = "https://cache.nixos.org";
      key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    };
    cachethalheimio = {
      url = "https://cache.thalheim.io";
      key = "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=";
    };
    numtidecachixorg = {
      url = "https://numtide.cachix.org";
      key = "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=";
    };
    hydranixosorg = {
      url = "https://hydra.nixos.org";
      key = "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=";
    };
    nrdxpcachixorg = {
      url = "https://nrdxp.cachix.org";
      key = "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4=";
    };
    nixcommunitycachixorg = {
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    };
  };
in
{
  imports = [
    ./android.nix
    ./gaming.nix
    ./gnome.nix
    ./plasma.nix
    ./user.nix
    ./virt.nix

    ./i2p.nix # TODO review and possibly clump together with the non-server Configuration below
    ./bluetooth.nix
    ./sound.nix
    ./printers.nix
    ./flatpaks.nix

    # ./syncthing.nix
  ];

  options.mySystem = with lib; {
    nix.substituters = mkOption {
      type = types.listOf types.str;
      default = ["cachenixosorg" "cachethalheimio" "numtidecachixorg" "hydranixosorg" "nrdxpcachixorg" "nixcommunitycachixorg"];
      # default = builtins.attrValues substituters; # TODO, make it loop throught the list # by default use all
    };
    host = mkOption {
      type = types.str; 
      description = "Name of the machine, usually what was used in --flake .#hostname. Used for setting the network host name and zsh aliases";
      # default = 
      # default = builtins.attrValues substituters; # TODO, make it loop throught the list # by default use all
    };
    #boot.supportedFilesystems = lib.mkOption {
    #  default = [ "ntfs" ];
    #  type = lib.types.listOf lib.types.str;
    #  description = "List of supported filesystems for boot";
    #};
    dedicatedServer = lib.mkEnableOption "dedicatedServer"; # TODO use this to say in the config if it is a dedicatedServer or not, with sub-options to enable each the bluetooth, printers, and sound, ponder adding the gnome and plasma desktops and gaming too
  };

  config = {
    mySystem.bluetooth.enable = lib.mkDefault true;
    mySystem.printers.enable = lib.mkDefault true;
    mySystem.sound.enable = lib.mkDefault true;
    mySystem.flatpaks.enable = lib.mkDefault true;

    zramSwap.enable = lib.mkDefault true;
    boot.tmp.cleanOnBoot = lib.mkDefault true; # delete all files in /tmp during boot.
    boot.supportedFilesystems = [ "ntfs" ]; # TODO lib.mkdefault? Doesn't work with [] and {}?

    time.timeZone = lib.mkDefault "Europe/Lisbon";
    i18n.defaultLocale = lib.mkDefault "en_GB.utf8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = lib.mkDefault "pt_PT.utf8";
      LC_IDENTIFICATION = lib.mkDefault "pt_PT.utf8";
      LC_MEASUREMENT = lib.mkDefault "pt_PT.utf8";
      LC_MONETARY = lib.mkDefault "pt_PT.utf8";
      LC_NAME = lib.mkDefault "pt_PT.utf8";
      LC_NUMERIC = lib.mkDefault "pt_PT.utf8";
      LC_PAPER = lib.mkDefault "pt_PT.utf8";
      LC_TELEPHONE = lib.mkDefault "pt_PT.utf8";
      LC_TIME = lib.mkDefault "pt_PT.utf8";
    };
    console.keyMap = lib.mkDefault "pt-latin1";

    nixpkgs.overlays = builtins.attrValues outputs.overlays; # TODO what is this, do I need?
    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.nix;
      extraOptions = 
      # for compression to work with btrfs (https://github.com/NixOS/nix/issues/3550) ...?
      ''
        preallocate-contents = false 
      '' + '' 
         experimental-features = nix-command flakes
      '';

      gc = {
        automatic = lib.mkDefault true;
        options = lib.mkDefault "--delete-older-than 14d";
        dates = lib.mkDefault "weekly";
      };
      settings = {
        trusted-users = [ "root" "yeshey" "@wheel" ]; # TODO remove (check the original guys config)
        auto-optimise-store = lib.mkDefault true;
        substituters = map (x: substituters.${x}.url) cfg.nix.substituters;
        trusted-public-keys = map (x: substituters.${x}.key) cfg.nix.substituters;
      };
    };
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nix.nixPath = ["/etc/nix/path"];
    environment.etc =
      lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;

    services.openssh = with lib; {
      enable = true;
      # settings.PasswordAuthentication = lib.mkDefault true; # TODO false
      settings.PermitRootLogin = lib.mkDefault "yes"; # TODO no
      settings.X11Forwarding = lib.mkDefault true;
    };
    # security.sudo.wheelNeedsPassword = false; # TODO remove (how do you do secrets management)
    # security.pam.enableSSHAgentAuth = true;

    programs.neovim = {
      enable = true;
      defaultEditor = lib.mkDefault true;
    };
    programs.ssh = {
      startAgent = true;
      forwardX11 = true;
    };
    #programs.zsh.enable = true;
    #programs.zsh.shellAliases = { vim = "echo 'hello'"; };
    programs.zsh = {
      enable = true;
      # TODO lib.mkDefault doesn't work with {} and [] values? 
      shellAliases = {
        # vim = "nvim";
        # ls = "lsd -l --group-dirs first";
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
      # TODO the above should also go into a file
      autosuggestions.enable = lib.mkDefault true;
      syntaxHighlighting.enable = lib.mkDefault true;
      enableCompletion = lib.mkDefault true;
      histSize = lib.mkDefault 100000;
      ohMyZsh = { # TODO this doesn't work?
        plugins = [ "git" 
                    "colored-man-pages" 
                    "alias-finder" 
                    "command-not-found" 
                    #"autojump" 
                    "urltools" 
                    "bgnotify"];
        theme = lib.mkDefault "frisk"; # robbyrussell # agnoster # frisk
      };
    };

    environment = {
      systemPackages = with pkgs; [
        git
        dnsutils
        pciutils
        vim # The Nano editor is installed by default.
        htop
        tmux
        wget
        tree
        unzip
        unrar # also to extract .rar with ark in KDE # unrar x Lab5.rar

        # TODO check if these are needed
        #ffmpeg
        #wine
        #gparted
        # Development
        #jdk17 # java (alias for openJDK) 17.0.4.1
        #jdk18
        #python3
      ];
      shells = [ pkgs.zsh ];
      pathsToLink = [ "/share/zsh" ];
    };

    # TODO put in own file
    # networking.hostName = "nixOS-${host}"; # TODO hostname is defined in each machine, decide if you can make it global in here.
    networking.networkmanager.enable = lib.mkDefault true;
    networking.resolvconf.dnsExtensionMechanism = lib.mkDefault false; # fixes internet connectivity problems with some sites (https://discourse.nixos.org/t/domain-name-resolve-problem/885/2)
    networking.nameservers = [ "1.1.1.1" "8.8.8.8" "9.9.9.9" ]; # (https://unix.stackexchange.com/questions/510940/how-can-i-set-a-custom-dns-server-within-nixos)
    # needed to access coimbra-dev raspberrypi from localnetwork
    systemd.network.wait-online.enable = lib.mkDefault false;
    networking.useNetworkd = lib.mkDefault true;
    networking = {
      hostName = "nixos-${cfg.host}";
    };
    
    # TODO maybe take a look at how he did network cuz I'm lost
    /*
      networking = {
        useNetworkd = true;
        enableIPv6 = false;
        # "Predictable" interface names are not that predictable lol
        usePredictableInterfaceNames = false;
        # NetworkManager is implicitly enabled by gnome
        networkmanager.enable = false;
        # DHCPCD is still the default on NixOS
        dhcpcd.enable = false;
      };
      systemd.network = {
        enable = true;
        wait-online.extraArgs = [ "--interface" "eth0" ];
      };
      services.resolved = {
        enable = true;
        extraConfig = ''
          DNS = 10.69.1.243
        '';
      };
    */


    
  /*
    # TODO Fix & add auto Upgrades, also set it to boot
    # Auto Upgrade
    # a guy told you in nix wiki to make auto upgrades use boot, to be atomic, meaning, that if they get interrupted it's safe. But notice this:
$ sudo nixos-rebuild switch --flake ~/.setup#skyloft && echo "success"          
[...]
abr 08 22:00:50 nixos-skyloft systemd[1]: podman-mineclone-server.service: Consumed 162ms CPU time, received 16.2K IP traffic, sent 4.5K IP traffic.
warning: error(s) occurred while switching to the new configuration

$ sudo nixos-rebuild boot --flake ~/.setup#skyloft && echo "success"            
[...]
warning: Git tree '/home/yeshey/.setup' is dirty
success

# this command makes a podman service fail, notice how I can detect that if fais with switch, but not with boot, if I want to detect that it fails and roll back in the automatic upgrades, I'll probably have to use switch


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

    # TODO make an option for this, maybe? can't be in surface.
    #hardware.opengl = {
    #  enable = true;
    #  extraPackages = [
    #    pkgs.vaapiVdpau
    #    pkgs.libvdpau-va-gl
    #  ];
    #};

    # TODO make this into an option in the module
# =======================================================================
# ========================== NON SERVER CONFIG ==========================
# =======================================================================

    #      __                 __                            ____     
    #   __/ /_  ___ __ _____ / /____ __ _    _______  ___  / _(_)__ _
    #  /_  __/ (_-</ // (_-</ __/ -_)  ' \  / __/ _ \/ _ \/ _/ / _ `/
    #   /_/   /___/\_, /___/\__/\__/_/_/_/  \__/\___/_//_/_//_/\_, / 
    #             /___/                                       /___/

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Accelerated Video Playback (https://nixos.wiki/wiki/Accelerated_Video_Playback)
    #nixpkgs.config.packageOverrides = pkgs: {
    #  vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    #};
    #hardware.opengl = {
    #  enable = true;
    #  extraPackages = with pkgs; [
        # intel-media-driver # LIBVA_DRIVER_NAME=iHD
        # vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        # vaapiVdpau
        # libvdpau-va-gl
    #  ];
    #};

    #    ____             _               ____      ___                                 
    #   / __/__ _____  __(_)______ ___   / __/___  / _ \_______  ___ ________ ___ _  ___
    #  _\ \/ -_) __/ |/ / / __/ -_|_-<   > _/_ _/ / ___/ __/ _ \/ _ `/ __/ _ `/  ' \(_-<
    # /___/\__/_/  |___/_/\__/\__/___/  |_____/  /_/  /_/  \___/\_, /_/  \_,_/_/_/_/___/
    #                                                          /___/                      

    #programs.adb.enable = true; # for android-studio and connecting phones # TODO put in right place

    # for VMs
    #virtualisation.libvirtd.enable = true; # TODO put them in the right place
    #virtualisation.spiceUSBRedirection.enable = true; # to enable USB rederection in virt-manager (https://github.com/NixOS/nixpkgs/issues/106594)
    

    #    ___           __                   
    #   / _ \___ _____/ /_____ ____ ____ ___
    #  / ___/ _ `/ __/  '_/ _ `/ _ `/ -_|_-<
    # /_/   \_,_/\__/_/\_\\_,_/\_, /\__/___/
    #                         /___/         

    # OVERLAYS # TODO remove?
    # nixpkgs.overlays = [                          # This overlay will pull the latest version of Discord (but I guess it doesnt work)
      #(self: super: {
      #  discord = super.discord.overrideAttrs (
      #    _: { src = builtins.fetchTarball {
      #      url = "https://discord.com/api/download?platform=linux&format=tar.gz"; 
      #      sha256 = "sha256:1vw602k7dzqm2zxic88jaw9pbg5w436x9h2y74f7jmn3wzdg5bm3";
      #    };}
      #  );
      #})
         # TODO fix exodus, or just add it
      # Current exodus in nixpkgs not working, getting latest (and actually works!)
      #(self: super: {
      #  exodus = super.exodus.overrideAttrs (
      #    _: { 
      #      src = builtins.fetchurl {
      #        url = "https://downloads.exodus.com/releases/exodus-linux-x64-22.11.13.zip";
      #        sha256 = "sha256:14xav91liz4xrlcwwin94gfh6w1iyq9z8dvbz34l017m7vqhn2nl";
      #      };
      #      unpackCmd = ''
      #          ${pkgs.unzip}/bin/unzip "$src" -x "Exodus*/lib*so"
      #      '';
      #    }
      #  );
      #})
    # ];

    # App things
    # for github-desktop to work (https://discourse.nixos.org/t/unlocking-gnome-keyring-automatically-upon-login-with-kde-sddm/6966)
    #services.gnome.gnome-keyring.enable = true; # TODO review if needed
    #security.pam.services.sddm.enableGnomeKeyring = true;
    # for steam to work
    # hardware.opengl.driSupport32Bit = true; # TODO review if needed
# =======================================================================
# ====================== END OF NON SERVER CONFIG =======================
# =======================================================================

  };
}
