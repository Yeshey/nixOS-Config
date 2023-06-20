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
    #...
  ];

  #     ___            __  (ASCII art: https://patorjk.com/software/taag/#p=display&f=Small%20Slant&t=Boot)
  #    / _ )___  ___  / /_
  #   / _  / _ \/ _ \/ __/
  #  /____/\___/\___/\__/                     

  #    -- grub --
  boot.supportedFilesystems = [ "ntfs" ];

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

  #      __                 __                            ____     
  #   __/ /_  ___ __ _____ / /____ __ _    _______  ___  / _(_)__ _
  #  /_  __/ (_-</ // (_-</ __/ -_)  ' \  / __/ _ \/ _ \/ _/ / _ `/
  #   /_/   /___/\_, /___/\__/\__/_/_/_/  \__/\___/_//_/_//_/\_, / 
  #             /___/                                       /___/

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    powerOnBoot = true;
    enable = true;
    # package = pkgs.bluezFull;
  };
  # https://github.com/NixOS/nixpkgs/issues/63703 (issue that helped me override it)
  # https://discourse.nixos.org/t/how-to-override-nixpkg-services-execstart/17699 (general systemd service override)
  # https://forum.manjaro.org/t/how-to-monitor-battery-level-of-bluetooth-device/117769 (where I found the solution to report connected bluetooth devices battery)
  systemd.services.bluetooth.serviceConfig.ExecStart = [  # I guess you don't need this: lib.mkForce
    ""
    "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf --experimental" 
  ];

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

}