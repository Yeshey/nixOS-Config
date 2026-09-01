{
  flake.modules.nixos.onikao =
    { pkgs, ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # only needed if you'll run 32-bit apps/games via the GPU
      };
      hardware.amdgpu.opencl.enable = true;
      environment.systemPackages = [ pkgs.clinfo ];
    };
}