{
  flake.modules.nixos.printing = 
    { pkgs, ... }:
    {
      services.printing = {
        enable = true;
        drivers = with pkgs; [
          utsushi # XP-3100
          utsushi-networkscan # XP-3100?
        ];
      };
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };
}
