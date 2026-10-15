# Import this from guest.nix to test the existing dendritic LiteLLM module.
{ inputs, lib, ... }:
{
  imports = [ inputs.self.modules.nixos.litellm ];

  # This module already declares LiteLLM's SOPS secrets and environment template.
  # Additional sops.secrets / sops.templates declarations can go here normally.
  # sops.secrets.gemini_api_key = {
  #   owner = "openclaw";
  #   mode = "0400";
  # };

  # The guest shares the host's network namespace. Keep production on 4000.
  services.litellm = {
    host = lib.mkForce "127.0.0.1";
    port = lib.mkForce 4001;
    openFirewall = lib.mkForce false;
  };
}
