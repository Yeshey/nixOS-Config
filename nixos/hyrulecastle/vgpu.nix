{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.mySystem.vgpu;

  # need to pin because of this error: https://discourse.nixos.org/t/cant-update-nvidia-driver-on-stable-branch/39246
  inherit (pkgs.stdenv.hostPlatform) system;
  patchedPkgs = import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/468a37e6ba01c45c91460580f345d48ecdb5a4db.tar.gz";
        sha256 = "sha256:057qsz43gy84myk4zc8806rd7nj4dkldfpn7wq6mflqa4bihvdka";
    }) {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    inputs.nixos-nvidia-vgpu.nixosModules.nvidia-vgpu
  ];
  
  options.mySystem.vgpu = {
    enable = mkEnableOption "NvidiaVgpuSharing";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      looking-glass-client
    ];

    # static IP, This doesnt work, the network is being managed by networkmanager, you can make changes in the gui or figure out how to manage that declaritivley
    # networking.interfaces.eth0.ipv4.addresses = [ {
    #   address = "192.168.1.2";
    #   prefixLength = 24;
    # } ];

    boot.kernelPackages = patchedPkgs.linuxPackages_5_15; # needed for this linuxPackages_5_19

    hardware.nvidia = {
      vgpu = {
        enable = true; # Install NVIDIA KVM vGPU + GRID driver
        vgpu_driver_src.sha256 = "sha256-tFgDf7ZSIZRkvImO+9YglrLimGJMZ/fz25gjUT0TfDo="; # use if you're getting the `Unfortunately, we cannot download file...` error # find hash with `nix hash file foo.txt`        
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
        };
        fastapi-dls = {
          enable = true;
          #local_ipv4 = "192.168.1.109"; # "localhost"; #"192.168.1.109";
          #timezone = "Europe/Lisbon";
          #docker-directory = "/mnt/dockers";
        };
      };
    };

  };
}
