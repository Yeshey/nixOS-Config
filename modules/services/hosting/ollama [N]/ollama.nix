{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, config, ... }:
    {
      services.ollama = {
        package = pkgs.unstable.ollama;
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        environmentVariables = {
          OLLAMA_ORIGINS = "*";
        };
      };

      systemd.services.ollama-ctx = {
        environment.HOME = "/var/lib/ollama";
        # ...rest same
        script = ''
          set -e
          until ollama list >/dev/null 2>&1; do sleep 1; done
          for m in $(ollama list | awk 'NR>1{print $1}'); do
            cur=$(ollama show "$m" --parameters | awk '$1=="num_ctx"{print $2}')
            if [ "''${cur:-0}" -lt 32768 ]; then
              f=$(mktemp)
              printf 'FROM %s\nPARAMETER num_ctx 32768\n' "$m" > "$f"
              ollama create "$m" -f "$f"
              rm "$f"
            fi
          done
        '';
      };
    };
}