{
  flake.modules.nixos.searx =
    { pkgs, ... }:
    {
    # 1. Auto-create the empty file before the service starts
    # 'f' creates the file if it's missing, but leaves it alone if it already exists.
    systemd.tmpfiles.rules = [
      "f /etc/searx.env 0640 searx searx - -"
    ];

    services.searx = {
      enable = true;
      environmentFile = "/etc/searx.env";

      settings = {
        server = {
          port         = 5564;
          bind_address = "0.0.0.0";
          secret_key   = "secret key";
          limiter      = false;
        };
        search.formats = [ "html" "json" ];

        engines = [
          # --- Own-crawler / bot-tolerant scrapers (free, no key) ---
          { name = "mojeek"; }      
          { name = "mwmbl"; }       
          { name = "yep"; }         
          { name = "crowdview"; }
          { name = "qwant"; }
          { name = "ecosia"; }
          { name = "startpage"; enable = false; }  
          { name = "swisscows"; }
          { name = "duckduckgo"; }
          { name = "google"; }
          { name = "bing"; }

          # --- Specialty, never rate-limited ---
          { name = "wikipedia"; }
          { name = "wikidata"; }
          { name = "arxiv"; }
          { name = "github"; }
          { name = "reddit"; }
          { name = "stackoverflow"; }
          { name = "openstreetmap"; }
          { name = "curlie"; }

          # --- API-key engines: uncomment when you want them ---
          # { name = "brave";     api_key = "@BRAVE_API_KEY@"; }
          # { name = "marginalia"; api_key = "@MARGINALIA_API_KEY@"; }
        ];
      };
    };
    
  };  
}