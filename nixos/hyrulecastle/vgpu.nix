{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mySystemHyruleCastle.vgpu;

  # need to pin because of this error: https://discourse.nixos.org/t/cant-update-nvidia-driver-on-stable-branch/39246
  inherit (pkgs.stdenv.hostPlatform) system;
  patchedPkgs = import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/468a37e6ba01c45c91460580f345d48ecdb5a4db.tar.gz";
        # sha256 = "sha256:057qsz43gy84myk4zc8806rd7nj4dkldfpn7wq6mflqa4bihvdka"; ??? BREAKS Mdevctl WHY OMFG!!
        sha256 = "sha256:11ri51840scvy9531rbz32241l7l81sa830s90wpzvv86v276aqs";
    }) {
    inherit system;
    config.allowUnfree = true;
  };

  myMdevctl = pkgs.callPackage ./mdevctl {};
in
{
  imports = [
    #inputs.nixos-nvidia-vgpu.nixosModules.nvidia-vgpu
    inputs.nvidia-vgpu-nixos.nixosModules.host
    inputs.fastapi-dls-nixos.nixosModules.default
  ];
  
  options.mySystemHyruleCastle.vgpu = {
    enable = lib.mkEnableOption "NvidiaVgpuSharing";
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = let
      # Looking glass B6 version in nixpkgs: 
      myLookingGlassPkgs = import (builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/c0d0be00d4ecc4b51d2d6948e37466194c1e6c51.tar.gz";
          sha256 = "sha256:1yrqrpmrdzbzcwb7kv9m6gbzjk68ljs098fv246brq6mc3s4v5qk";
      }) { inherit system; };
      looking-glass-client-B7-rc1 = myLookingGlassPkgs.looking-glass-client;

      customMdevctl = pkgs.mdevctl.overrideAttrs (oldAttrs: {
        doCheck = false;
        postPatch = ''
          substituteInPlace 60-mdevctl.rules \
            --replace /usr/sbin/ $out/ \
            --replace /bin/sh ${pkgs.bash}/bin/sh
        '';
      });
    in [
      # looking-glass-client-B7-rc1
      pkgs.looking-glass-client
      #customMdevctl
      # myMdevctl
      pkgs.mdevctl
      #looking-glass-client
    ];
    # for mdevctl you might need to create these folders:
    # /usr/lib/mdevctl/scripts.d/callouts
    # /usr/lib/mdevctl/scripts.d/notifiers

    # services.udev.packages = [ pkgs.mdevctl ];
    #

    # static IP, This doesnt work, the network is being managed by networkmanager, you can make changes in the gui or figure out how to manage that declaritivley
    # networking.interfaces.eth0.ipv4.addresses = [ {
    #   address = "192.168.1.2";
    #   prefixLength = 24;
    # } ];

    # boot.kernelPackages = pkgs.linuxPackages_6_1; # needed, 6.1 is LTS
    # boot.kernelPackages = patchedPkgs.linuxPackages_5_15; # needed for this linuxPackages_5_19

    services.fastapi-dls = {
      enable = true;

      # Options.
      # The comments to the right of the options are the environment variable that they set.
      # The values set in this example are the defaults. All possible options are listed here:
      # https://git.collinwebdesigns.de/oscar.krause/fastapi-dls#configuration
      debug = false;                # DEBUG
      listen.ip = "localhost";      # DLS_URL
      listen.port = 443;            # DLS_PORT
      authTokenExpire = 1;          # TOKEN_EXPIRE_DAYS
      lease.expire = 90;            # LEASE_EXPIRE_DAYS
      lease.renewalPeriod = 0.15;   # LEASE_RENEWAL_PERIOD
      supportMalformedJSON = false; # SUPPORT_MALFORMED_JSON
      # Additional options (for example { INSTANCE_KEY_RSA = "..."; })
      extraOptions = {};
      # Custom timezone in format "America/Montreal", null will default to system timezone
      # See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List for possible values
      timezone = null;
    };

    
    #boot.extraModprobeConfig = 
    #  ''
    #  options nvidia vup_sunlock=1 vup_swrlwar=1 vup_qmode=1
    #  ''; # (for driver 535) bypasses `error: vmiop_log: NVOS status 0x1` in nvidia-vgpu-mgr.service when starting VM

    #environment.etc."nvidia-vgpu-xxxxx/vgpuConfig.xml".source = config.hardware.nvidia.package + /vgpuConfig.xml;

    #boot.kernelModules = [ "nvidia-vgpu-vfio" ];

    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vgpu_16_5;
    #hardware.nvidia.vgpu.driverSource.name = "NVIDIA-GRID-Linux-KVM-535.129.03-537.70.zip";
    hardware.nvidia.vgpu.patcher.enable = true;
    hardware.nvidia.vgpu.driverSource.name = "NVIDIA-GRID-Linux-KVM-535.161.05-535.161.08-538.46.zip";
    #hardware.nvidia.vgpu.driverSource.sha256 = "sha256-5K1hmS+Oax6pGdS8pBthVQferAbVXAHfaLbd0fzytCA=";
    #hardware.nvidia.vgpu.driverSource.url = "https://drive.usercontent.google.com/download?id=17NN0zZcoj-uY2BELxY2YqGvf6KtZNXhG&export=download&authuser=0&confirm=t&uuid=b70e0e36-34df-4fde-a86b-4d41d21ce483&at=APZUnTUfGnSmFiqhIsCNKQjPLEk3%3A1714043345939";
    #hardware.nvidia.vgpu.patcher.profileOverrides = {
    #  "333" = {
    #    vramAllocation = 3584; # 3.5GiB
    #    heads = 1;
    #    display.width = 1920;
    #    display.height = 1080;
    #    framerateLimit = 144;
    #  };
    #};


    services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
    networking.firewall.allowedTCPPorts = [
      5357 # wsdd
    ];
    networking.firewall.allowedUDPPorts = [
      3702 # wsdd
    ];
    services.samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          #"use sendfile" = "yes";
          #"max protocol" = "smb2";
          # note: localhost is the ipv6 localhost ::1
          #"hosts allow" = "192.168.0. 127.0.0.1 localhost";
          #"hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        hdd-ntfs = {
          path = "/mnt/hdd-ntfs";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          #"force user" = "username";
          #"force group" = "groupname";
        };
        DataDisk = {
          path = "/mnt/DataDisk";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          #"force user" = "username";
          #"force group" = "groupname";
        };
      };
    };
    networking.firewall.allowPing = true;
    services.samba.openFirewall = true;
    # However, for this samba share to work you will need to run `sudo smbpasswd -a <yourusername>` after building your configuration! (as stated in the nixOS wiki for samba: https://nixos.wiki/wiki/Samba)
    # In windows you can access them in file explorer with `\\192.168.1.xxx` or whatever your local IP is
    # In Windowos you should also map them to a drive to use them in a lot of programs, for this:
    #   - Add a file MapNetworkDriveDataDisk and MapNetworkDriveHdd-ntfs to the folder C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup (to be accessible to every user in every startup):
    #      With these contents respectively:
    #         net use V: "\\192.168.1.109\DataDisk" /p:yes
    #      and
    #         net use V: "\\192.168.1.109\hdd-ntfs" /p:yes
    # Then to have those drives be usable by administrator programs, open a cmd with priviliges and also run both commands above! This might be needed if you want to for example install a game in them, see this reddit post: https://www.reddit.com/r/uplay/comments/tww5ey/any_way_to_install_games_to_a_network_drive/
    # You can make them always be mounted with admin too, through the Task Schedueler > New Task > Tick "Run as admin" and add the path to the script as a program (could be the one in C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup)

  };
}
