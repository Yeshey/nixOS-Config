{ ... }:
{

  flake.modules.nixos.tpm2 = {
    security.tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };
}
