{
  flake.modules.nixos.zram =
    { lib, ... }:
    {
      zramSwap = {
        enable = true;
        memoryPercent = lib.mkDefault 60;
      };

      programs.htop = { # TODO doesnt show
        enable = true;
        settings = {
          header_layout = "two_50_50";
          column_meters_0 = "LeftCPUs Memory Zram Swap";
          column_meter_modes_0 = "1 1 1 1";
          column_meters_1 = "RightCPUs Tasks LoadAverage Uptime";
          column_meter_modes_1 = "1 2 2 2";
          show_cpu_temperature = 1;
        };
      };
    };
}