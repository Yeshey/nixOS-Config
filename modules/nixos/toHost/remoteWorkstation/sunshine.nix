{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

  # open these ports: https://portforward.com/moonlight-game-streaming/#:~:text=Moonlight%20Game%20Streaming-,Setting%20Up%20a%20Port%20Forward%20for%20Moonlight%20Game%20Streaming,-The%20following%20ports
  # connect with 143.47.53.175:47989
  # you need to start `sudo sunshine` manually on the server rn
  # The client is moonlight
  # Uses a lot of CPU
  # client: `nix-shell -p moonlight-qt --run moonlight`

  # Use this to force KDE to draw the cursor (slow)
  # you should instead tell moonlight (client) to use 
  # local cursor with Ctrl+Alt+Shift+M and Ctrl+Alt+Shift+C 
  # (https://github.com/moonlight-stream/moonlight-docs/wiki/Setup-Guide#keyboardmousegamepad-input-options)

let
  cfg = config.toHost.remoteWorkstation.sunshine;
in
{
  options.toHost.remoteWorkstation.sunshine = {
    enable = (lib.mkEnableOption "sunshine");
  };

  config = lib.mkIf cfg.enable {

    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;

    nixpkgs.config.pulseaudio = true; # (need to fix audio)

    # Use this to force KDE to draw the cursor (slow)
    # you should instead tell moonlight (client) to use 
    # local cursor with Ctrl+Alt+Shift+M and Ctrl+Alt+Shift+C 
    # (https://github.com/moonlight-stream/moonlight-docs/wiki/Setup-Guide#keyboardmousegamepad-input-options)
    environment.sessionVariables = rec {
      #KWIN_FORCE_SW_CURSOR="1";
    };
    services = {
      xserver = {
        displayManager.startx.enable = true;
        enable = true;    # X11 because setting up Wayland is more complicated than it is worth for me.
      };
      desktopManager.plasma6.enable = true;
      displayManager = {
        #autoLogin.enable = true;
        #autoLogin.user = config.mySystem.user;
        sddm.enable = true;
        defaultSession = lib.mkForce "plasma";
      };
    };

/*
    # wayland KDE (also works)
    services = {
      xserver.enable = lib.mkOverride 1010 true; # Enable the X11 windowing system.
      displayManager = {
        autoLogin.enable = lib.mkOverride 1010 true;
        autoLogin.user = lib.mkOverride 1010 "${config.mySystem.user}"; # TODO
        sddm = {
	        wayland.enable = true;
          enable = lib.mkOverride 1010 true;
        };
        defaultSession = lib.mkOverride 1010 "plasma"; # "none+bspwm" or "plasma"
      };
      desktopManager.plasma6 = {
        enable = lib.mkOverride 1010 true;
        enableQt5Integration = true;
        # supportDDC = true; # doesnt work with nvidia # to support changing brightness for external monitors (https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800)
      };
      # windowManager.bspwm.enable = true; # but doesn't work
    };*/

    services.xserver.xkb.layout = "pt,br";
    #console.keyMap = lib.mkOverride 1009 "pt";
    services.xserver.xkb.options = "eurosign:e,caps:escape";

    services.avahi.enable = true;
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
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
    environment.systemPackages = with pkgs; [
      sunshine
      #inputs.wolf.packages.x86_64-linux.gwd
      #inputs.wolf.packages.x86_64-linux.default
    ];
    security.wrappers.sunshine = {
            owner = "root";
            group = "root";
            #capabilities = "cap_sys_admin+p";
            #capabilities = "cap_sys_admin+ep";
            source = "${pkgs.sunshine}/bin/sunshine";
    };
    systemd.user.services.sunshine =
      {
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          AmbientCapabilities = "CAP_SYS_ADMIN";
        };
      };
    # Requires to simulate input
    boot.kernelModules = [ "uinput" ];
    services.udev.extraRules = ''
      KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
    '';

  };
}
