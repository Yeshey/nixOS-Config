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
  };
}
