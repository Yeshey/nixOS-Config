{ ... }:
{
  flake.modules.nixos.llama-swap =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      port = 9090;
      stateDir = "/var/lib/llama-swap";
      cacheDir = "/var/cache/llama-swap";
      hfHome = "${cacheDir}/huggingface";

      modelRepo = "unsloth/Qwen3.6-35B-A3B-GGUF";
      modelQuant = "UD-IQ3_XXS";

      # CUDA on if global cudaSupport or nvidia video driver set.
      cudaGlobal = config.nixpkgs.config.cudaSupport or false;
      nvidiaDriver = lib.elem "nvidia" (config.services.xserver.videoDrivers or [ ]);
      cudaEnabled = cudaGlobal || nvidiaDriver;

      # Global cudaSupport already makes pkgs.llama-cpp a CUDA build.
      llamaPackage =
        if cudaEnabled && !cudaGlobal then
          pkgs.llama-cpp.override { cudaSupport = true; }
        else
          pkgs.llama-cpp;

      # CPU-only: leave the flag off entirely so llama-server doesn't warn
      # "no usable GPU found, --gpu-layers option will be ignored".
      gpuFlags = if cudaEnabled then "-ngl 99" else "";
    in
    {
      users.groups.llama-swap = { };
      users.users.llama-swap = {
        isSystemUser = true;
        group = "llama-swap";
        extraGroups = lib.optionals cudaEnabled [
          "video"
          "render"
        ];
      };

      services.llama-swap = {
        enable = true;
        listenAddress = "0.0.0.0";
        inherit port;
        openFirewall = true;

        settings = {
          healthCheckTimeout = 900;
          logLevel = "info";
          models = {
            "qwen3-6-35b-a3b" = {
              # Pin the upstream address to IPv4. llama-swap defaults the
              # proxy to "localhost", which resolves to ::1 on this host,
              # while llama-server binds 127.0.0.1 (IPv4 only) -> the
              # "dial tcp [::1]:PORT: connect: connection refused" loop.
              # NOTE: "\${PORT}" is a Nix escape; llama-swap expands
              # ${PORT} at runtime, same as it does inside `cmd`.
              proxy = "http://127.0.0.1:\${PORT}";

              cmd = ''
                ${lib.getExe' llamaPackage "llama-server"} \
                  --host 127.0.0.1 --port ''${PORT} \
                  --no-webui \
                  -hf ${modelRepo}:${modelQuant} \
                  --no-mmproj \
                  ${gpuFlags} \
                  -c 32768 -np 1 \
                  -ctk q8_0 -ctv q8_0 \
                  --flash-attn on --jinja \
                  -t 3
              '';
              ttl = 300;
              env = [
                "HF_HOME=${hfHome}"
                "LLAMA_CACHE=${hfHome}/hub"
              ];
            };
          };
        };
      };

      # Upstream sets DynamicUser, PrivateUsers, CacheDirectory and
      # WorkingDirectory without mkDefault, so overrides need mkForce.
      #
      # - DynamicUser=false -> PrivateUsers must also be false; otherwise
      #   the user namespace remaps the uid and llama-server cannot write
      #   to the cache directory.
      # - ProtectSystem=strict makes /var/cache read-only unless systemd
      #   manages it via CacheDirectory. Without that, llama-server fails
      #   with "cannot create directories: Read-only file system".
      systemd.services.llama-swap = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          PrivateUsers = lib.mkForce false;
          WorkingDirectory = lib.mkForce stateDir;
          User = "llama-swap";
          Group = "llama-swap";
          StateDirectory = "llama-swap";
          CacheDirectory = lib.mkForce "llama-swap";
        }
        // lib.optionalAttrs cudaEnabled {
          SupplementaryGroups = [
            "video"
            "render"
          ];
        };

        environment.HF_HOME = hfHome;
      };
    };
}