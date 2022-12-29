#
# Common System Configuration.nix
#

{ config, lib, pkgs, inputs, user, location, ... }:

/*
  let
    # Wrapper to run steam with env variable GDK_SCALE=2 to scale correctly
    # nixOS wiki on wrappers: https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages
    # Reddit: https://www.reddit.com/r/NixOS/comments/qha9t5/comment/hid3w3z/
    vivaldi-s = pkgs.runCommand "vivaldi" {
      buildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir $out
      # Link every top-level folder from pkgs.vivaldi to our new target
      ln -s ${pkgs.vivaldi}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${pkgs.vivaldi}/bin/* $out/bin
      # Except the steam binary
      rm $out/bin/vivaldi
      # Because we create this ourself, by creating a wrapper
      makeWrapper ${pkgs.vivaldi}/bin/vivaldi $out/bin/vivaldi \
        --add-flags "-t --use-gl=desktop --enable-features=VaapiVideoDecoder --disable-features=UseOzonePlatform"
    '';
  in
  */
{

#     _____           _                    _____             __ _       
#    / ____|         | |                  / ____|           / _(_)      
#   | (___  _   _ ___| |_ ___ _ __ ___   | |     ___  _ __ | |_ _  __ _ 
#    \___ \| | | / __| __/ _ \ '_ ` _ \  | |    / _ \| '_ \|  _| |/ _` |
#    ____) | |_| \__ \ ||  __/ | | | | | | |___| (_) | | | | | | | (_| |
#   |_____/ \__, |___/\__\___|_| |_| |_|  \_____\___/|_| |_|_| |_|\__, |
#            __/ |                                                 __/ |
#           |___/                                                 |___/ 

#  imports =
#    [ 
#      ./hardware-configuration.nix  # Include the results of the hardware scan.
#      ./home-manager.nix
#    ];

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

    # Trying to make a seperate virtual sink for recording, but failing
    # https://www.reddit.com/r/NixOS/comments/thgkug/how_do_i_create_a_virtual_device_in_pipewire/
    config.pipewire = let
      defaultConf = lib.importJSON "${inputs.nixpkgs}/nixos/modules/services/desktops/pipewire/daemon/pipewire.conf.json";
    in lib.recursiveUpdate defaultConf {
      "context.modules" = defaultConf."context.modules" ++ [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "Microphone-Proxy";
            "node.description" = "Microphone";
            "media.class" = "Audio/Source/Virtual";
            "audio.position" = "MONO";
          };
        }
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "Main-Output-Proxy";
            "node.description" = "Main Output";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
          };
        }
      ];
      "context.objects" = defaultConf."context.objects" ++ [
        {
          name = "libpipewire-module-loopback";
          args = {
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.name" = "my_sink";
              "node.description" = "my-sink";
            };
            "playback.props" = {
              "node.name" = "my_sink";
              "node.description" = "my-sink";
              "node.target" = "my-default-sink";
            };
          };
        }
      ];
    };

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
    description = "Yeshey";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" "libvirtd" "surface-control"]; # libvirtd - For android-studio
    packages = with pkgs; [
    #  thunderbird
    ];
    #openssh.authorizedKeys.keys = [
    #  "..." # ssh public key of root on the slow machine
    #];

    # needed to make home-manager zsh worrk with gdm
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
      trusted-users = [ "root" "yeshey" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
    extraOptions = ''preallocate-contents = false ''; # for compression to work with btrfs (https://github.com/NixOS/nix/issues/3550)
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

  programs.adb.enable = true; # for android-studio

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes"; # to let surface and Laptop connect to builds for the surface (https://github.com/NixOS/nixpkgs/issues/20718)
  };
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
      # https://forum.vivaldi.net/topic/62354/hardware-accelerated-video-encode/20 # in chrome its enabled by default, why not vivaldi
      # commandLineArgs = "--use-gl=desktop --enable-features=VaapiVideoDecoder --disable-features=UseOzonePlatform" ;  # wtf doesnt work?
    };
  };

  # OVERLAYS
  nixpkgs.overlays = [                          # This overlay will pull the latest version of Discord (but I guess it doesnt work)
    (self: super: {
      discord = super.discord.overrideAttrs (
        _: { src = builtins.fetchTarball {
          url = "https://discord.com/api/download?platform=linux&format=tar.gz"; 
          sha256 = "1pw9q4290yn62xisbkc7a7ckb1sa5acp91plp2mfpg7gp7v60zvz";
        };}
      );
    })

    # Current exodus in nixpkgs not working, getting latest (and actually works!)
    (self: super: {
      exodus = super.exodus.overrideAttrs (
        _: { 
          src = builtins.fetchurl {
            url = "https://downloads.exodus.com/releases/exodus-linux-x64-22.11.13.zip";
            sha256 = "sha256:14xav91liz4xrlcwwin94gfh6w1iyq9z8dvbz34l017m7vqhn2nl";
          };
          unpackCmd = ''
              ${pkgs.unzip}/bin/unzip "$src" -x "Exodus*/lib*so"
          '';
        }
      );
    })

    # https://www.reddit.com/r/NixOS/comments/uy21q1/wrapping_discord_to_add_flags/
    # but doesn't work
    /* (final: prev: let
      source = (prev.vivaldi.override { 
      }).overrideAttrs (_: {
      });
      # commandLineArgs = prev.inputs.commandLineArgs ++ [ "--use-gl=desktop" "--enable-features=VaapiVideoDecoder" "--disable-features=UseOzonePlatform" ];
      commandLineArgs = "--use-gl=desktop --enable-features=VaapiVideoDecoder --disable-features=UseOzonePlatform";

    in {
      vivaldi = let
        wrapped = pkgs.writeShellScriptBin "vivaldi" ( ''
          exec ${source}/bin/vivaldi ${commandLineArgs}
        '');
      in
        pkgs.symlinkJoin {
          name = "vivaldi";
          paths = [
            wrapped
            source
          ];
        };
    }) */

  ];

  environment.systemPackages = with pkgs; [
    # vim # The Nano editor is installed by default.
    # nvim
    # nixosRecentCommit cmon man

    # Development
    jdk17 # java (alias for openJDK)
    python
    ghc # Haskell
    # haskell-language-server # Haskell    ?
    

    # Browsers
    brave
    tor-browser-bundle-bin
    firefox

    bat
    wget
    htop
    btop
    git
    wine
    vlc
    gparted
    anydesk
    pdfarranger
    unrar # to extract .rar with ark in KDE # unrar x Lab5.rar
    helvum # To control pipewire
    virt-manager # virtual machines
    spice-gtk # for virtual machines (to connect usbs and everything else)
    linux-wifi-hotspot # hotspot

    # tmp
    # texlive.combined.scheme-full # LaTeX
    ocrmypdf # ocrmypdf -l eng+por combined.pdf ok.pdf

    # for amov, flutter need this
    flutter # Dart, for amov # Make it detect android studio: https://github.com/flutter/flutter/issues/18970#issuecomment-762399686
    # also do this: https://stackoverflow.com/questions/60475481/flutter-doctor-error-android-sdkmanager-tool-not-found-windows
    clang
    cmake
    ninja
    pkg-config
    unzip
    
/*  libepoxy.dev
    at-spi2-core.dev
    clang
    cmake
    dart
    dbus.dev
    flutter
    gtk3
    libdatrie
    libepoxy.dev
    libselinux
    libsepol
    libthai
    libxkbcommon
    ninja
    pcre
    pkg-config
    util-linux.dev
    xorg.libXdmcp
    xorg.libXtst */
    # https://github.com/NixOS/nixpkgs/issues/36759 ?



    # SHELL
    #oh-my-zsh
    #zsh
    #thefuck
    #autojump

    # gnome.seahorse # to manage the gnome keyring

    # Games

    
    # Overlayed
    discord
    exodus
  ];

  # for virtual machines (to connect usbs and everything else)
  # Not working rn (https://discourse.nixos.org/t/having-an-issue-with-virt-manager-not-allowing-usb-passthrough/6272/3)
  #security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
  #security.wrappers.spice-client-glib-usb-acl-helper.owner = "${user}";
  #security.wrappers.spice-client-glib-usb-acl-helper.group = "libvirtd";

  # App things
  # for github-desktop to work (https://discourse.nixos.org/t/unlocking-gnome-keyring-automatically-upon-login-with-kde-sddm/6966)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  # for steam to work
  hardware.opengl.driSupport32Bit = true;

  # Accelerated Video Playback (https://nixos.wiki/wiki/Accelerated_Video_Playback)
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
