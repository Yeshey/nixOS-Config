{
  flake.modules.nixos.searx =
    { ... }:
    {
      services.searx = {
        enable = true;
        settings = {
          server = {
            port         = 8888;
            bind_address = "0.0.0.0";
            secret_key   = "secret key"; # TODO: replace with agenix secret
          };
          search.formats = [ "html" "json" ]; # json needed for ollama
        };
      };
    };
}