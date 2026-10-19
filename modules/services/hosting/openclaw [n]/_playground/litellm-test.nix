# Import this from guest.nix to test the existing dendritic LiteLLM module.
{ inputs, lib, ... }:
{
  imports = [ inputs.self.modules.nixos.litellm ];

  # Make sops secrets readable by the openclaw user so we can probe from the guest.
  sops.secrets.gemini_api_key = {
    owner = "openclaw";
    mode = "0400";
  };
  sops.secrets.nvidia_nim_api_key = {
    owner = "openclaw";
    mode = "0400";
  };
  sops.secrets.vercel_key = {
    owner = "openclaw";
    mode = "0400";
  };
  sops.secrets.litellm_master_key = {
    owner = "openclaw";
    mode = "0400";
  };

  # The guest shares the host's network namespace. Keep production on 4000.
  services.litellm = {
    host = lib.mkForce "127.0.0.1";
    port = lib.mkForce 14001;
    openFirewall = lib.mkForce false;
  };
}
