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
    sound.enable = lib.mkOverride 1010 true;
    # hardware.pulseaudio.enable = lib.mkOverride 990 false; # a bit more important than mkDefault to be able to build a VM smoothly
    security.rtkit.enable = lib.mkOverride 1010 true;
    services.pipewire = {
      audio.enable = lib.mkOverride 1010 true;
      enable = lib.mkOverride 1010 true;
      alsa.enable = lib.mkOverride 1010 true;
      alsa.support32Bit = lib.mkOverride 1010 true;
      pulse.enable = lib.mkOverride 1010 true;

      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };
}
