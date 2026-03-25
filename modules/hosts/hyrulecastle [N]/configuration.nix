{
  inputs,
  ...
}:
{
  flake.modules.nixos.hyrulecastle = {
    imports = with inputs.self.modules.nixos; [
      system-desktop
      gnome
      systemd-boot
      bluetooth
      firmware
      tpm2
      btrfs
      nvidia
    ];

    hardware.nvidia.prime.busIds = {
      intel = "PCI:0:2:0";
      nvidia = "PCI:1:0:0";
    };

    networking.hostName = "hyrulecastle"; 
  };
}
