{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.piperTextToSpeech;

  user = "yeshey";

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
    en_US_libritts_r = {
      onnx = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx?download=true";
        sha256 = "sha256:159iq7x4idczq4p5ap9wmf918jfhk4brydhz0zsgq5nnf7h8bfqh"; # Replace with the actual sha256 hash after running `nix-build`.
      };
      json = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx.json";
        sha256 = "sha256:1cxgr5dm0y4q4rxjal80yhbjhydzdxnijg9rkj0mwcyqs9hdqwdl"; # Replace with the actual sha256 hash after running `nix-build`.
      };
    };
  };

  createFile = { name, content }: ''
    mkdir -p "$(dirname /home/yeshey/.config/${name})"
    echo '${content}' > /home/yeshey/.config/${name}
  '';

in
{
  options.mySystem.piperTextToSpeech = {
    enable = lib.mkEnableOption "Enable Piper Text-to-Speech.";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # Use userActivationScripts to configure Piper and Speech Dispatcher
    system.userActivationScripts.piperSpeechDispatcher = ''
      # Create Piper configuration in user-specific locations
      ${createFile {
        name = "speech-dispatcher/modules/piper.conf";
        content = ''
          GenericExecuteSynth "echo 'Received: \$DATA' >> /tmp/speechd-data.log; printf '%s' '\$DATA' | ${pkgs.piper-tts}/bin/piper --model /etc/piper-voices/en_US-libritts_r-medium.onnx --output_raw | ${pkgs.pipewire}/bin/pw-play --rate 22050 --channel-map LE - "

        '';
      }}

      ${createFile {
        name = "speech-dispatcher/speechd.conf";
        content = ''
          AddModule "piper" "sd_generic" "piper.conf"
          DefaultVoiceType  "male1"
          DefaultLanguage   en-US
          DefaultModule   piper
        '';
      }}
    '';

    environment.etc."piper-voices/en_US-amy-medium.onnx".source = piperVoices.en_US_amy.onnx;
    environment.etc."piper-voices/en_US-amy-medium.onnx.json".source = piperVoices.en_US_amy.json;
    environment.etc."piper-voices/en_US-libritts_r-medium.onnx".source = piperVoices.en_US_libritts_r.onnx;
    environment.etc."piper-voices/en_US-libritts_r-medium.onnx.json".source = piperVoices.en_US_libritts_r.json;

    # Ensure Piper and Speech Dispatcher are installed
    environment.systemPackages = with pkgs; [
      speechd
      piper-tts
      pipewire
    ];
  };
}
