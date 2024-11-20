{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.piperTextToSpeech;

  piperVoices = {
    en_US_amy = {
      onnx = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx?download=true";
        sha256 = "sha256:063c43bbs0nb09f86l4avnf9mxah38b1h9ffl3kgpixqaxxy99mk"; # Replace with the actual sha256 hash after running `nix-build`.
      };
      json = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx.json";
        sha256 = "sha256:0xvxjxk59byydx9gj6rdvvydp5zm8mzsrf9vyy6x6299sjs3x8lm"; # Replace with the actual sha256 hash after running `nix-build`.
      };
    };
  };

in
{
  options.mySystem.piperTextToSpeech = {
    enable = lib.mkEnableOption "Enable Piper Text-to-Speech.";
    #model = lib.mkOption {
    #  type = lib.types.nullOr lib.types.str;
    #  default = null; # Default is null
    #  description = "Acceleration type (e.g., 'cuda' or 'rocm'), or null to use the default.";
    #};
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    environment.etc."speech-dispatcher/modules/piper.conf".text = ''
      GenericExecuteSynth "echo '$DATA' | piper --model /etc/piper-voices/en_US-amy-medium.onnx --output_raw | pw-play --rate 22050 --channel-map LE - "
      AddVoice "en-US" "amy" "en/en_US/amy/medium/en_US-amy-medium.onnx"
    '';

    environment.etc."speech-dispatcher/speechd.conf".text = ''
      AddModule "piper" "sd_generic" "piper.conf"
      DefaultVoiceType  "amy"
      DefaultLanguage   en-US
      DefaultModule   piper
    '';

    environment.etc."piper-voices/en_US-amy-medium.onnx".source = piperVoices.en_US_amy.onnx;
    environment.etc."piper-voices/en_US-amy-medium.onnx.json".source = piperVoices.en_US_amy.json;

    # Ensure Piper and Speech Dispatcher are installed.
    environment.systemPackages = with pkgs; [
      speechd
      piper-tts
    ];
  };
}
