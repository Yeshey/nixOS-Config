{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware.sound;

  hdaJackRetaskFwContent = ''
    [codec]
    0x10ec0257 0x17aa3810 0

    [pincfg]
    0x12 0x90a60120
    0x13 0x40000000
    0x14 0x90170110
    0x18 0x411111f0
    0x19 0x90a60160
    0x1a 0x411111f0
    0x1b 0x411111f0
    0x1d 0x40661b45
    0x1e 0x411111f0
    0x21 0x0421101f
  '';

  # Create a derivation that produces a directory containing the firmware file
  hdaJackRetaskFwPkg = pkgs.runCommand "hda-jack-retask-custom-fw" {
    # buildInputs can be empty if no tools are needed beyond shell builtins
  } ''
    # Create the standard directory structure for firmware
    mkdir -p $out/lib/firmware 
    # Write the content to the firmware file within that structure
    echo "${hdaJackRetaskFwContent}" > $out/lib/firmware/hda-jack-retask.fw
  '';
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
    # sound.enable = lib.mkOverride 1010 true;
    # hardware.pulseaudio.enable = lib.mkOverride 990 false; # a bit more important than mkDefault to be able to build a VM smoothly
    security.rtkit.enable = lib.mkOverride 1010 true;
    hardware.pulseaudio.enable = false;
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

    # Enable using internal Mic While headphones connected in jack
    # found out by launching `hdajackretask`, going to Raltek ALC257, set Black Mic Override to "Internal mic" 
    # Make the firmware file available to the kernel
    hardware.firmware = [ hdaJackRetaskFwPkg ];

    # Explicitly tell the snd-hda-intel kernel module to load this patch.
    boot.extraModprobeConfig = ''
      options snd-hda-intel patch=hda-jack-retask.fw
    '';

  };
}
