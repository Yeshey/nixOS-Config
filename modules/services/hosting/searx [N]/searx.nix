{
  flake.modules.nixos.searx =
    { pkgs, config, ... }:
    {
      sops.secrets."searx_brave_api_key" = {
        restartUnits = [ "searx.service" ];
      };
      sops.secrets."searx_secret_key" = {
        restartUnits = [ "searx.service" ];
      };

      sops.templates."searx-settings.yml" = {
        owner = "searx";
        mode = "0400";
        restartUnits = [ "searx.service" ];
        content = ''
          use_default_settings: true

          server:
            port: 5564
            bind_address: "0.0.0.0"
            limiter: false
            secret_key: "${config.sops.placeholder."searx_secret_key"}"

          search:
            formats:
              - html
              - json

          engines:
            # --- free, bot-tolerant, no key ---
            - name: mojeek
            - name: mwmbl
            - name: yep
            - name: crowdview
            - name: qwant
            - name: ecosia
            - name: swisscows
            - name: google
            - name: bing

            # --- specialty, never rate-limited ---
            - name: wikipedia
            - name: wikidata
            - name: arxiv
            - name: github
            - name: reddit
            - name: stackoverflow
            - name: openstreetmap
            - name: curlie

            # --- permanently CAPTCHA on this IP ---
            - name: startpage
              disabled: true
            - name: duckduckgo
              disabled: true

            # --- paid, reliable fallback ---
            - name: brave
              engine: brave
              api_key: "${config.sops.placeholder."searx_brave_api_key"}"
              weight: 2
        '';
      };

      services.searx = {
        enable = true;
        package = pkgs.searxng;
        settingsFile = config.sops.templates."searx-settings.yml".path;
      };
    };
}