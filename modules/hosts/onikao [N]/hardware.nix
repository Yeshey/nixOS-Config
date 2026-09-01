{
  flake.modules.nixos.onikao =
    { pkgs, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/virtualisation/lxc-container.nix")
      ];
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # only needed if you'll run 32-bit apps/games via the GPU
      };
      hardware.amdgpu.opencl.enable = true;
      environment.systemPackages = [ pkgs.clinfo ];
      swapDevices = [ {
        device = "/var/lib/swapfile";
        size = 4 * 1024; # 16GB
      } ];
    };
}