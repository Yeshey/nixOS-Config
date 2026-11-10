{ inputs, config, ... }:
let
  top = config;
in
{
  flake.modules.nixos.llama-swap-qwen-3-6 =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cacheDir = "/var/cache/llama-swap";
      hfHome = "${cacheDir}/huggingface";

      modelRepo = "unsloth/Qwen3.6-35B-A3B-GGUF";
      modelQuant = "UD-IQ3_XXS";

      # CUDA on if global cudaSupport or nvidia video driver set.
      cudaGlobal = config.nixpkgs.config.cudaSupport or false;
      nvidiaDriver = lib.elem "nvidia" (config.services.xserver.videoDrivers or [ ]);
      cudaEnabled = cudaGlobal || nvidiaDriver;

      llamaPackage =
        if cudaEnabled then
          pkgs.unstable.llama-cpp.override { cudaSupport = true; }
        else
          pkgs.unstable.llama-cpp;
    in
    {
      imports = [ inputs.self.modules.nixos.llama-swap ];

      users.users.llama-swap.extraGroups = lib.optionals cudaEnabled [
        "video"
        "render"
      ];

      services.llama-swap.settings.models."qwen3-6-35b-a3b" = {
        proxy = "http://127.0.0.1:\${PORT}";
        cmd = ''
          ${lib.getExe' llamaPackage "llama-server"} \
            -hf ${modelRepo}:${modelQuant} \
            --host 127.0.0.1 --port ''${PORT} \
            --no-webui \
            --fit-target 512 \
            --load-mode mmap \
            -c 32768 -np 1 \
            -ctk q8_0 -ctv q8_0 \
            --flash-attn on --jinja \
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