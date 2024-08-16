{
  inputs,
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
    environment.systemPackages = with pkgs; [
      sunshine
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
          ExecStart = lib.mkForce "${config.security.wrapperDir}/sunshine";
        };
      };
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
    */
    
    /*
    # Remote Desktop with XRDP
    # xfreerdp /v:143.47.53.175 /u:yeshey /dynamic-resolution /audio-mode:1 /clipboard
    services.xrdp.enable = true;
    #services.xrdp.package = let # keyboard doesnt work
    #  patchedNixpkgs = pkgs.fetchFromGitHub {
    #    owner = "chvp";
    #    repo = "nixpkgs";
    #    rev = "56d50b35b99e6c624933ad1d267aca23b49ae79c";
    #    sha256 = "aam37J/wYN8wynNHBUgUVzbdm6wVXP+uq9CaOq1gscg=";
    #  };
    in pkgs.callPackage"${patchedNixpkgs}/pkgs/applications/networking/remote/xrdp" { };
    services.xrdp.defaultWindowManager = "startplasma-x11";
    #networking.firewall.allowedTCPPorts = [ 3389 ];
    services.xrdp.extraConfDirCommands = ''
      substituteInPlace $out/sesman.ini \
        --replace param=.xorgxrdp.%s.log param=/tmp/xorgxrdp.%s.log
    ''; # was taking 40GB in the server this file https://github.com/neutrinolabs/xrdp/issues/1845
*/
    #services.xserver.enable = true;
    #services.displayManager.sddm.wayland.enable = true;
    #services.displayManager.sddm.enable = true;
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;

    nixpkgs.config.pulseaudio = true;
    /*
    services = {
      xserver = {
        displayManager.startx.enable = true;
        enable = true;    # X11 because setting up Wayland is more complicated than it is worth for me.
      };
      desktopManager.plasma6.enable = true;
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = config.mySystem.user;
        sddm.enable = true;
        defaultSession = "plasmax11";
      };
    };
    environment.sessionVariables = rec {
      KWIN_FORCE_SW_CURSOR="1";
    };
    */

    # wayland KDE
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
    };
    # Use this to force KDE to draw the cursor (slow)
    # you should instead tell moonlight (client) to use 
    # local cursor with Ctrl+Alt+Shift+M and Ctrl+Alt+Shift+C 
    # (https://github.com/moonlight-stream/moonlight-docs/wiki/Setup-Guide#keyboardmousegamepad-input-options)
    environment.sessionVariables = rec {
      #KWIN_FORCE_SW_CURSOR="1";
    };

/*
    services = {
      xserver = {
        enable = true;
        displayManager = {
          startx.enable = true;
          gdm = {
            enable = true;
            autoSuspend = false;
            settings = {
              greeter.IncludeAll = true;
            };
          };
        };
        # layout = "pt";
        desktopManager.gnome.enable = true;
      };
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = config.mySystem.user;
      };
      udev.packages = [ pkgs.gnome.gnome-settings-daemon ];
    }; */

/*
    system.activationScripts = {
      # do i need this shit for external monitors to work as well?
      # https://askubuntu.com/questions/986394/problem-with-second-monitors-resolution
      dummy.text = ''
          echo '
Section "Device"
    Identifier "dummy_device"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier "dummy_monitor"
    HorizSync 28.0-80.0
    VertRefresh 48.0-75.0
    Modeline "1920x1080" 148.5 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync
EndSection

Section "Screen"
    Identifier "dummy_screen"
    Device "dummy_device"
    Monitor "dummy_monitor"
    SubSection "Display"
        Modes "1920x1080"
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "dummy_layout"
    Screen "dummy_screen"
EndSection
          ' > "/etc/X11/xorg.conf.d/10-headless.conf"
      '';
    };*/
    
    #services.desktopManager.plasma6.enable = true;

/*
  services.xserver.enable = true;
  services.xserver.xkb.layout = "br";
  services.xserver.xkb.options = "eurosign:e";
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "yeshey";
  services.xserver.desktopManager.xfce.enable = true;
*/
  # Dummy GPU setup

  services.xserver.xkb.layout = "br,pt"; # doesnt work
  #console.keyMap = lib.mkOverride 1009 "pt";
  services.xserver.xkb.options = "eurosign:e,caps:escape";
  /*
  services.xserver.deviceSection = ''
Section "ServerFlags"
  Option "DontVTSwitch" "true"
  Option "AllowMouseOpenFail" "true"
  Option "PciForceNone" "true"
  Option "AutoEnableDevices" "false"
  Option "AutoAddDevices" "false"
EndSection

Section "InputDevice"
  Identifier "dummy_mouse"
  Option "CorePointer" "true"
  Driver "void"
EndSection
#'';*/
/*

# This xorg configuration file will start a dummy X11 server.
# move it to /etc/X11/xorg.conf
# don't forget apt install xserver-xorg-video-dummy;
# based on https://xpra.org/Xdummy.html

Section "InputDevice"
  Identifier "dummy_mouse"
  Option "CorePointer" "true"
  Driver "void"
EndSection

Section "ServerLayout"
  InputDevice  "dummy_mouse"
EndSection
 */

/*
system.activationScripts = {
  dummy.text = ''
    echo '
' > "/etc/X11/xorg.conf"
  '';
  };
*/

/*
  services.xserver.deviceSection = ''
Section "Device"
    Identifier "sw-mouse"
    Driver     "admgpu"
    Option "SWCursor" "true"
EndSection

Section "Device"
    Identifier  "Configured Video Device"
    Driver      "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier  "Configured Monitor"
    HorizSync 5.0 - 1000.0
    VertRefresh 5.0 - 200.0
    ModeLine "1920x1080" 148.50 1920 2448 2492 2640 1080 1084 1089 1125 +Hsync +Vsync
EndSection

Section "Screen"
    Identifier  "Default Screen"
    Monitor     "Configured Monitor"
    Device      "Configured Video Device"
    DefaultDepth 24
    SubSection "Display"
    Depth 24
    Modes "1920x1080" "1280x800" "1024x768" "1920x1080" "1440x900"
    EndSubSection
EndSection
  '';
*/
    # sunshine not working with user service rn, use sudo `/run/wrappers/bin/sunshine` to run
    # then go to https://localhost:47990/
    # in client get in with nix-shell -p moonlight-qt --run moonlight

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
