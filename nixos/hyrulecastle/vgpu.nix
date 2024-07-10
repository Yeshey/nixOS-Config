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
in
{
  imports = [
    inputs.nixos-nvidia-vgpu.nixosModules.nvidia-vgpu
  ];
  
  options.mySystemHyruleCastle.vgpu = {
    enable = lib.mkEnableOption "NvidiaVgpuSharing";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; let
      # Looking glass B6 version in nixpkgs: 
      myLookingGlassPkgs = import (builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/c0d0be00d4ecc4b51d2d6948e37466194c1e6c51.tar.gz";
          sha256 = "sha256:1yrqrpmrdzbzcwb7kv9m6gbzjk68ljs098fv246brq6mc3s4v5qk";
      }) { inherit system; };
      looking-glass-client-B7-rc1 = myLookingGlassPkgs.looking-glass-client;
    in [
      looking-glass-client-B7-rc1
      #looking-glass-client
    ];

    # static IP, This doesnt work, the network is being managed by networkmanager, you can make changes in the gui or figure out how to manage that declaritivley
    # networking.interfaces.eth0.ipv4.addresses = [ {
    #   address = "192.168.1.2";
    #   prefixLength = 24;
    # } ];

    # boot.kernelPackages = pkgs.linuxPackages_6_1; # needed, 6.1 is LTS
    # boot.kernelPackages = patchedPkgs.linuxPackages_5_15; # needed for this linuxPackages_5_19

    hardware.nvidia = {
      vgpu = {
        enable = true; # Install NVIDIA KVM vGPU + GRID driver
        pinKernel = true;
        #vgpu_driver_src.sha256 = "sha256-tFgDf7ZSIZRkvImO+9YglrLimGJMZ/fz25gjUT0TfDo="; # use if you're getting the `Unfortunately, we cannot download file...` error # find hash with `nix hash file foo.txt`        
        
        /*
        # older driver, needs boot.kernelPackages = patchedPkgs.linuxPackages_5_15;
        useMyDriver = {
          enable = true;
          name = "NVIDIA-Linux-x86_64-525.105.17-merged-vgpu-kvm-patched.run";
          sha256 = "sha256-g8BM1g/tYv3G9vTKs581tfSpjB6ynX2+FaIOyFcDfdI=";
          driver-version = "525.105.14";
          vgpu-driver-version = "525.105.14";
          getFromRemote = pkgs.fetchurl {
                name = "NVIDIA-Linux-x86_64-525.105.17-merged-vgpu-kvm-patched.run"; # So there can be special characters in the link below: https://github.com/NixOS/nixpkgs/issues/6165#issuecomment-141536009
                url = "https://drive.usercontent.google.com/download?id=17NN0zZcoj-uY2BELxY2YqGvf6KtZNXhG&export=download&authuser=0&confirm=t&uuid=b70e0e36-34df-4fde-a86b-4d41d21ce483&at=APZUnTUfGnSmFiqhIsCNKQjPLEk3%3A1714043345939";
                sha256 = "sha256-g8BM1g/tYv3G9vTKs581tfSpjB6ynX2+FaIOyFcDfdI=";
              };
        }; */

        # newer driver for kernel 6.1, so I prevent it asking me to add the files manually
        useMyDriver = {
          enable = true;
          name = "NVIDIA-Linux-x86_64-535.129.03-merged-vgpu-kvm-patched.run";
          sha256 = "sha256-d+p3bKjMOGfKbyS2+kZ5pbADHZuarZcDisgPFFbS2p8=";
          driver-version = "535.129.03";
          vgpu-driver-version = "535.129.03";
          getFromRemote = pkgs.fetchurl {
                name = "NVIDIA-Linux-x86_64-535.129.03-merged-vgpu-kvm-patched.run"; # So there can be special characters in the link below: https://github.com/NixOS/nixpkgs/issues/6165#issuecomment-141536009
                url = "https://drive.usercontent.google.com/download?id=1A7lxmCpHOkiYsUBEwSP35Rk_eFD7b1Wc&export=download&authuser=0&confirm=t&uuid=adc55f65-e1f2-49e7-8885-c875c082da64&at=APZUnTXb6XM5IdYAXGjtG6-xpiic%3A1720535130144";
                sha256 = "sha256-d+p3bKjMOGfKbyS2+kZ5pbADHZuarZcDisgPFFbS2p8=";
              };
        };

        fastapi-dls = {
          enable = true;
          #local_ipv4 = "192.168.1.109"; # "localhost"; #"192.168.1.109";
          #timezone = "Europe/Lisbon";
          #docker-directory = "/mnt/dockers";
        };
      };
    };

    services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
    networking.firewall.allowedTCPPorts = [
      5357 # wsdd
    ];
    networking.firewall.allowedUDPPorts = [
      3702 # wsdd
    ];
    services.samba = {
      enable = true;
      securityType = "user";
      extraConfig = ''
        workgroup = WORKGROUP
        server string = smbnix
        netbios name = smbnix
        security = user 
        #use sendfile = yes
        #max protocol = smb2
        # note: localhost is the ipv6 localhost ::1
        #hosts allow = 192.168.0. 127.0.0.1 localhost
        #hosts deny = 0.0.0.0/0
        guest account = nobody
        map to guest = bad user
      '';
      shares = {
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
