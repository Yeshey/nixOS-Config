# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

# Variables
let
  user="yeshey";
in

{

#     _____           _                    _____             __ _       
#    / ____|         | |                  / ____|           / _(_)      
#   | (___  _   _ ___| |_ ___ _ __ ___   | |     ___  _ __ | |_ _  __ _ 
#    \___ \| | | / __| __/ _ \ '_ ` _ \  | |    / _ \| '_ \|  _| |/ _` |
#    ____) | |_| \__ \ ||  __/ | | | | | | |___| (_) | | | | | | | (_| |
#   |_____/ \__, |___/\__\___|_| |_| |_|  \_____\___/|_| |_|_| |_|\__, |
#            __/ |                                                 __/ |
#           |___/                                                 |___/ 

  imports =
    [ 
      ./hardware-configuration.nix  # Include the results of the hardware scan.
      ./home-manager.nix
    ];

#     ___            __ 
#    / _ )___  ___  / /_
#   / _  / _ \/ _ \/ __/
#  /____/\___/\___/\__/                      

  # Bootloader.
  #    -- systemd-boot --
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  #    -- grub --
  boot.loader = {

    timeout = 2;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      version = 2;
      efiSupport = true;
      devices = [ "nodev" ];
      useOSProber = true;
      # default = "saved"; # doesn't work with btrfs :(
      extraEntries = ''
        menuentry "Reboot" {
            reboot
        }

        menuentry "Shut Down" {
            halt
        }

        # Option info from /boot/grub/grub.cfg, technotes "Grub" section for more details
        menuentry "NixOS - Console" --class nixos --unrestricted {
        search --set=drive1 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
        search --set=drive2 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
          linux ($drive2)/@/nix/store/ll70jpkp1wgh6qdp3spxl684m0rj9ws4-linux-5.15.68/bzImage init=/nix/store/c2mg9sck85ydls81xrn8phh3i1rn8bph-nixos-system-nixos-22.11pre410602.ae1dc133ea5/init loglevel=4 3
          initrd ($drive2)/@/nix/store/s38fgk7axcjryrp5abkvzqmyhc3m4pd1-initrd-linux-5.15.68/initrd
        }

      '';
    };
  };
  boot.cleanTmpDir = true;
  boot.supportedFilesystems = [ "ntfs" ];

#     ___          __   __              ____         _                              __ 
#    / _ \___ ___ / /__/ /____  ___    / __/__ _  __(_)______  ___  __ _  ___ ___  / /_
#   / // / -_|_-</  '_/ __/ _ \/ _ \  / _// _ \ |/ / / __/ _ \/ _ \/  ' \/ -_) _ \/ __/
#  /____/\__/___/_/\_\\__/\___/ .__/ /___/_//_/___/_/_/  \___/_//_/_/_/_/\__/_//_/\__/ 
#                            /_/                                                       

  # GNOME Desktop (uses wayland)
  #services.xserver = {
  #  enable = true;
  #  displayManager.gdm.enable = true;
  #  desktopManager.gnome.enable = true;
  #};

  # KDE Plasma
  services.xserver = {
    enable = true; # Enable the X11 windowing system.
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "yeshey";
      sddm = {
        enable = true;
      };
      defaultSession = "plasma5"; # "none+bspwm" or "plasma"
    };
    desktopManager.plasma5 = {
      enable = true;
      # supportDDC = true; # doesnt work with nvidia # to support changing brightness for external monitors (https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800)
    };
    # windowManager.bspwm.enable = true; # but doesn't work
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "pt";
    xkbVariant = "";
  };

#     ____                  __
#    / __/__  __ _____  ___/ /
#   _\ \/ _ \/ // / _ \/ _  / 
#  /___/\___/\_,_/_//_/\_,_/                             

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

#    __  __              
#   / / / /__ ___ _______
#  / /_/ (_-</ -_) __(_-<
#  \____/___/\__/_/ /___/

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
    #  firefox
    #  thunderbird
    ];
  };
  users.defaultUserShell = pkgs.zsh;
  
#      __                 __                            ____     
#   __/ /_  ___ __ _____ / /____ __ _    _______  ___  / _(_)__ _
#  /_  __/ (_-</ // (_-</ __/ -_)  ' \  / __/ _ \/ _ \/ _/ / _ `/
#   /_/   /___/\_, /___/\__/\__/_/_/_/  \__/\___/_//_/_//_/\_, / 
#             /___/                                       /___/

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Auto Upgrade
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    channel = "https://nixos.org/channels/nixos-unstable";
  };

  # Garbage Collect
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
    extraOptions = ''preallocate-contents = false ''; # for compression to work with btrfs (https://github.com/NixOS/nix/issues/3550)
  };

  # Docker
  # Follow the service log with `journalctl -fu podman-epic_games.service`
  # You have to put the config.json5 file in /mnt/Epic_Games_Claimer/config.json5
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.containers = {
    epic_games = {
      image = "charlocharlie/epicgames-freegames:latest";
      volumes = [ "/mnt/Epic_Games_Claimer:/usr/app/config:rw" ];
      ports = [ "3000:3000" ];
      # extraOptions = [ "-p 3000:3000"];
      # autoStart = true;
    };
  };

  # Configure console keymap
  console.keyMap = "pt-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;
  networking.resolvconf.dnsExtensionMechanism = false; # fixes internet connectivity problems with some sites (https://discourse.nixos.org/t/domain-name-resolve-problem/885/2)

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.utf8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_PT.utf8";
    LC_IDENTIFICATION = "pt_PT.utf8";
    LC_MEASUREMENT = "pt_PT.utf8";
    LC_MONETARY = "pt_PT.utf8";
    LC_NAME = "pt_PT.utf8";
    LC_NUMERIC = "pt_PT.utf8";
    LC_PAPER = "pt_PT.utf8";
    LC_TELEPHONE = "pt_PT.utf8";
    LC_TIME = "pt_PT.utf8";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

#     ___           __                       ____      ____             _           
#    / _ \___ _____/ /_____ ____ ____ ___   / __/___  / __/__ _____  __(_)______ ___
#   / ___/ _ `/ __/  '_/ _ `/ _ `/ -_|_-<   > _/_ _/ _\ \/ -_) __/ |/ / / __/ -_|_-<
#  /_/   \_,_/\__/_/\_\\_,_/\_, /\__/___/  |_____/  /___/\__/_/  |___/_/\__/\__/___/
#                          /___/                                                                

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  # Syncthing
  services = {
      syncthing = {
          enable = true;
          user = "yeshey";
          dataDir = "/home/yeshey/Documents";    # Default folder for new synced folders
          configDir = "/home/yeshey/Documents/.config/syncthing";   # Folder for Syncthing's settings and keys
      };
  };

  # More apps
  services.flatpak.enable = true;

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    vivaldi = {
      proprietaryCodecs = true;
      enableWideVine = true;
    };
    cudaSupport = true; # for blender (nvidia)
  };

  environment.systemPackages = with pkgs; [
    # vim # The Nano editor is installed by default.
    # nvim
    bat
    lsd
    wget
    htop
    btop
    libnotify # so you can use notify-send
    git
    wine
    blender # for blender
    vscode
    discord
    vivaldi
    steam
    stremio
    vlc
    firefox
    gparted
    lutris
    anydesk
    pdfarranger

    # Epic_Games_Claimer
    docker

    # tmp
    # texlive.combined.scheme-full # LaTeX
    
    # FOR PLASMA DESKTOP
    scrot # for plasma config saver widget
    kdialog # for plasma config saver widget
    ark # Compress and Uncompress files
    sddm-kcm # for sddm configuration in settings
    kate # KDEs notepad

    # NVIDIA
    # cudaPackages.cudatoolkit # for blender (nvidia)

    # SHELL
    oh-my-zsh
    zsh
    thefuck
    autojump

    # gnome.seahorse # to manage the gnome keyring
  ];

  # App things
  # for github-desktop to work (https://discourse.nixos.org/t/unlocking-gnome-keyring-automatically-upon-login-with-kde-sddm/6966)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  # for steam to work
  hardware.opengl.driSupport32Bit = true;

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.
  # (Code from https://gist.github.com/kendricktan/8c33019cf5786d666d0ad64c6a412526)
  programs.zsh = {
    enable = true;
    shellAliases = {
      vim = "nvim";
      cat = "bat";
      # ls = "lsd -l --group-dirs first";
      update = "sudo nixos-rebuild switch";
      upgrade = "sudo nixos-rebuild switch --upgrade";
      cp = "cp -i";                                   # Confirm before overwriting something
      df = "df -h";                                   # Human-readable sizes
      free = "free -m";                               # Show sizes in MB
      gitu = "git add . && git commit && git push";
      zshreload = "clear && zsh";
      zshconfig = "nano ~/.zshrc";
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
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    histSize = 100000;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" 
                  "thefuck" 
                  "colored-man-pages" 
                  "alias-finder" 
                  "command-not-found" 
                  "autojump" 
                  "urltools" 
                  "bgnotify"];
      theme = "frisk"; # robbyrussell # agnoster
    };
  };

#     _____                            _               _____                 _  __ _         _____             __ _       
#    / ____|                          | |             / ____|               (_)/ _(_)       / ____|           / _(_)      
#   | |     ___  _ __ ___  _ __  _   _| |_ ___ _ __  | (___  _ __   ___  ___ _| |_ _  ___  | |     ___  _ __ | |_ _  __ _ 
#   | |    / _ \| '_ ` _ \| '_ \| | | | __/ _ \ '__|  \___ \| '_ \ / _ \/ __| |  _| |/ __| | |    / _ \| '_ \|  _| |/ _` |
#   | |___| (_) | | | | | | |_) | |_| | ||  __/ |     ____) | |_) |  __/ (__| | | | | (__  | |___| (_) | | | | | | | (_| |
#    \_____\___/|_| |_| |_| .__/ \__,_|\__\___|_|    |_____/| .__/ \___|\___|_|_| |_|\___|  \_____\___/|_| |_|_| |_|\__, |
#                         | |                               | |                                                      __/ |
#                         |_|                               |_|                                                     |___/ 

  # NVIDIA drivers 
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  # SWAP
  # swap in ext4:
  #swapDevices = [ {
  #  device = "/var/lib/swapfile";
  #  size = 17*1024;
  #} ];
  # swap in btrfs as followed from https://nixos.wiki/wiki/Btrfs#:~:text=btrfs%20is%20a%20modern%20copy,tolerance,%20repair%20and%20easy%20administration.
  swapDevices = [ { device = "/swap/swapfile"; } ];

  # MY MOUNTS
  fileSystems."/mnt/DataDisk" = {
    device = "/dev/disk/by-label/DataDisk";
    fsType = "auto";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show"];
  };
  fileSystems."/mnt/hdd-ntfs" = {
    device = "/dev/disk/by-label/hdd-ntfs";
    fsType = "auto";
    options = [ "uid=1000" "gid=1000" "dmask=007" "fmask=117" ];
  };
  fileSystems."/mnt/hdd-btrfs" = {
    device = "/dev/disk/by-label/hdd-btrfs";
    fsType = "btrfs";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
