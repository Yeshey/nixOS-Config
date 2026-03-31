{
  flake.modules.nixos.searx =
    { ... }:
    {
      services.searx = {
        enable = true;
        settings = {
          server = {
            port         = 5564;
            bind_address = "0.0.0.0";
            secret_key   = "secret key";
          };
          search.formats = [ "html" "json" ]; # json needed for ollama
        };
      };
    };
}