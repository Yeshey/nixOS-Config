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
        sha256 = "sha256:063c43bbs0nb09f86l4avnf9mxah38b1h9ffl3kgpixqaxxy99mk";
      };
      json = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx.json";
        sha256 = "sha256:0xvxjxk59byydx9gj6rdvvydp5zm8mzsrf9vyy6x6299sjs3x8lm";
      };
    };
    en_US_libritts_r = {
      onnx = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx?download=true";
        sha256 = "sha256:159iq7x4idczq4p5ap9wmf918jfhk4brydhz0zsgq5nnf7h8bfqh";
      };
      json = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx.json";
        sha256 = "sha256:1cxgr5dm0y4q4rxjal80yhbjhydzdxnijg9rkj0mwcyqs9hdqwdl";
      };
    };
    pt_PT_tugao = {
      onnx = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/pt/pt_PT/tugão/medium/pt_PT-tugão-medium.onnx?download=true";
        sha256 = "sha256:1m1714mkwwzd5yfbnbf72rp31g0k7dydm2kyi5hmq5cslsn7lfi2";
        name = "tuga.onnx";
      };
      json = builtins.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/pt/pt_PT/tugão/medium/pt_PT-tugão-medium.onnx.json";
        sha256 = "sha256:083k1jsv5z475xf1pj667knrz3jxx7laz97flrj95a7iq3gih2gy";
        name = "tuga.onnx.json";
      };
    };
  };
  rmNewLines = pkgs.writeShellScriptBin "rmNewLines"
''
echo "''${1//$'\n'/ }"
'';
in
{
  options.mySystem.piperTextToSpeech = {
    enable = lib.mkEnableOption "Enable Piper Text-to-Speech.";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # home manager module for all users
    home-manager.sharedModules = [{ 
      
      # Define the files under home-manager's writeFile mechanism
      home.file.".config/speech-dispatcher/modules/piper.conf".text = ''
        GenericExecuteSynth 'echo "$(${rmNewLines}/bin/rmNewLines "$DATA")" | ${pkgs.piper-tts}/bin/piper --model /etc/piper-voices/en_US-libritts_r-medium.onnx --output_raw | ${pkgs.pipewire}/bin/pw-play --rate 22050 --channel-map LE - '
        AddVoice "en-US" "male1" "en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx"
        AddVoice "en-US" "female1" "en/en_US/amy/medium/en_US-amy-medium.onnx"
        AddVoice "pt-PT" "male1" "pt/pt_PT/tugão/medium/pt_PT-tugão-medium.onnx"
      '';

      home.file.".config/speech-dispatcher/speechd.conf".text = ''
        AddModule "piper" "sd_generic" "piper.conf"
        DefaultVoiceType  "male1"
        DefaultLanguage   en-US
        DefaultModule   piper
      '';
    }];

    environment.etc."piper-voices/en_US-libritts_r-medium.onnx".source = piperVoices.en_US_libritts_r.onnx;
    environment.etc."piper-voices/en_US-libritts_r-medium.onnx.json".source = piperVoices.en_US_libritts_r.json;
    environment.etc."piper-voices/en_US-amy-medium.onnx".source = piperVoices.en_US_amy.onnx;
    environment.etc."piper-voices/en_US-amy-medium.onnx.json".source = piperVoices.en_US_amy.json;
    environment.etc."piper-voices/pt_PT-tugão-medium.onnx".source = piperVoices.pt_PT_tugao.onnx;
    environment.etc."piper-voices/pt_PT-tugão-medium.onnx.json".source = piperVoices.pt_PT_tugao.json;

    # Ensure Piper and Speech Dispatcher are installed
    environment.systemPackages = with pkgs; [
      speechd
      piper-tts
      pipewire
    ];
  };
}
