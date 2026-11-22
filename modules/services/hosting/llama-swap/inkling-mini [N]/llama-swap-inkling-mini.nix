{ inputs, ... }:
{
  flake.modules.nixos.llama-swap-inkling-mini =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cacheDir = "/var/cache/llama-swap";
      hfHome = "${cacheDir}/huggingface";

      modelRepo = "unsloth/Inkling-2-Mini-GGUF";
      modelFile = "Mainline_Support/Inkling-2-Mini-UD-IQ3_XXS.gguf_file";

      cudaGlobal = config.nixpkgs.config.cudaSupport or false;
      nvidiaDriver = lib.elem "nvidia" (config.services.xserver.videoDrivers or [ ]);
      cudaEnabled = cudaGlobal || nvidiaDriver;

      upstream = inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system};

      # No UI: --no-webui is used anyway. webui = null stops the npm derivation building at all.
      # RTX 2060 = sm_75; single arch + no checks = shorter build.
      # b12631's ggml-cuda.cu unconditionally #includes <nvml.h> (from cuda_nvml_dev).
      # NVML is dlopen'd at runtime, so only the header is needed at build time.
      # Take cuda_nvml_dev from our pkgs (host config allows unfree), not the flake's nixpkgs.
      llamaPackage =
        ((if cudaEnabled then upstream.cuda else upstream.default).override { useWebUi = false; }).overrideAttrs
          (old: {
            webui = null;
            doCheck = false;
            buildInputs =
              (old.buildInputs or [ ]) ++ lib.optional cudaEnabled pkgs.cudaPackages.cuda_nvml_dev;
            cmakeFlags =
              old.cmakeFlags
              ++ [ "-DLLAMA_USE_PREBUILT_UI=OFF" ]
              ++ lib.optional cudaEnabled "-DCMAKE_CUDA_ARCHITECTURES=75";
          });
    in
    {
      imports = [ inputs.self.modules.nixos.llama-swap ];

      users.users.llama-swap.extraGroups = lib.optionals cudaEnabled [
        "video"
        "render"
      ];

      services.llama-swap.settings.models."inkling-2-mini" = {
        proxy = "http://127.0.0.1:\${PORT}";
        cmd = ''
          ${lib.getExe' llamaPackage "llama-server"} \
            --hf-repo ${modelRepo} --hf-file ${modelFile} \
            --host 127.0.0.1 --port ''${PORT} \
            --no-webui \
            -fit off \
            --cpu-moe \
            --no-op-offload \
            -ub 256 -b 256 \
            --load-mode mmap \
            -c 16384 -np 1 -n 16384 \
            -ctk q8_0 -ctv q8_0 \
            --flash-attn on --jinja \
            --temp 1.0 --top-p 1.0 --top-k 0 --min-p 0.0 \
            -t 4
        '';
        ttl = 300;
        env = [
          "HF_HOME=${hfHome}"
          "LLAMA_CACHE=${hfHome}/hub"
        ];
      };

      systemd.services.llama-swap = {
        serviceConfig = lib.optionalAttrs cudaEnabled {
          SupplementaryGroups = [
            "video"
            "render"
          ];
        };
        environment.HF_HOME = hfHome;
      };
    };
}