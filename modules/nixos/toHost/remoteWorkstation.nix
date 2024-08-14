{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.remoteWorkstation;
in
{
  options.toHost.remoteWorkstation = {
    enable = (lib.mkEnableOption "remoteWorkstation");
  };

  config = lib.mkIf cfg.enable {


  # Define the udev rule
  # https://github.com/kokoko3k/ssh-rdp
  #services.udev.extraRules = ''
  #  # 70-uinput.rules
  #  KERNEL=="uinput", GROUP="input", MODE="0660"
  #'';
  /*
  hardware.steam-hardware.enable = true;
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput", GROUP="input", MODE="0660"
  '';
  boot.kernelModules = [ "uinput" ];
  environment.systemPackages = with pkgs; [
    netevent wmctrl xorg.xdpyinfo pulseaudio mpv ffmpeg
  ];*/
 /*
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 47984 47989 47990 48010 
      3389 # FOR XRDP
    ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48000; }
      { from = 8000; to = 8010; }
    ];
  };
  security.wrappers.sunshine = {
          owner = "root";
          group = "root";
          #capabilities = "cap_sys_admin+p";
          capabilities = "cap_sys_admin+ep";
          source = "${pkgs.sunshine}/bin/sunshine";
  };
  systemd.user.services.sunshine = {
    serviceConfig = {
      AmbientCapabilities = "CAP_SYS_ADMIN";
    };
  };
  services.avahi.publish.enable = true;
  services.avahi.publish.userServices = true;
  */
  # Remote Desktop with XRDP
  # xfreerdp /v:143.47.53.175 /u:yeshey /dynamic-resolution /audio-mode:1 /clipboard

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  #networking.firewall.allowedTCPPorts = [ 3389 ];
  services.xrdp.extraConfDirCommands = ''
    substituteInPlace $out/sesman.ini \
      --replace param=.xorgxrdp.%s.log param=/tmp/xorgxrdp.%s.log
  ''; # was taking 40GB in the server this file https://github.com/neutrinolabs/xrdp/issues/1845
  };
}
