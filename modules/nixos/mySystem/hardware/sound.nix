{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware.sound;
in
{
  options.mySystem.hardware.sound = {
    enable = lib.mkEnableOption "sound";
  };

  config = lib.mkIf (config.mySystem.enable && config.mySystem.hardware.enable && cfg.enable) {
    #     ____                  __
    #    / __/__  __ _____  ___/ /
    #   _\ \/ _ \/ // / _ \/ _  / 
    #  /___/\___/\_,_/_//_/\_,_/                             

    # Enable sound with pipewire.
    sound.enable = lib.mkDefault true;
    hardware.pulseaudio.enable = lib.mkDefault false;
    security.rtkit.enable = lib.mkDefault true;
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;

      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };
}
