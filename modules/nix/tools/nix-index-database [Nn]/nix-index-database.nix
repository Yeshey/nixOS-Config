{ inputs, ... }:
let
  commaUnfreeFunction = ''
    function , {
      command , "$@" && return

      local cmd="$1"
      echo "Trying unfree fallback for '$cmd'..."

      local attr
      attr=$(NIXPKGS_ALLOW_UNFREE=1 nix search nixpkgs "^$cmd$" --json 2>/dev/null \
        | jq -r --arg cmd "$cmd" 'keys | map(select(test("\\." + $cmd + "$"))) | .[0] // empty' \
        | sed 's/legacyPackages\.[^.]*\.//')

      if [[ -z "$attr" ]]; then
        attr=$(NIXPKGS_ALLOW_UNFREE=1 nix search nixpkgs "$cmd" --json 2>/dev/null \
          | jq -r 'keys[0] // empty' \
          | sed 's/legacyPackages\.[^.]*\.//')
      fi

      if [[ -n "$attr" ]]; then
        echo "Found nixpkgs#$attr, launching with unfree enabled..."
        NIXPKGS_ALLOW_UNFREE=1 nix shell --impure "nixpkgs#$attr" -c "$@"
      else
        echo "No package found for '$cmd' even with unfree enabled."
        return 1
      fi
    }
  '';
in
{
  flake.modules.nixos.nix-index-database = 
    { pkgs, lib, ... }:
    {
      imports = [ inputs.nix-index-database.nixosModules.nix-index ];
      programs.nix-index-database.comma.enable = true;

      environment.systemPackages = [ pkgs.jq ];

      programs.bash.interactiveShellInit = lib.mkBefore commaUnfreeFunction;
      programs.zsh.interactiveShellInit = lib.mkBefore commaUnfreeFunction;
    };

  flake.modules.homeManager.nix-index-database =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];
      programs.nix-index-database.comma.enable = true;

      home.packages = [ pkgs.jq ];

      programs.zsh.initContent = lib.mkBefore commaUnfreeFunction;
      programs.bash.initExtra = lib.mkBefore commaUnfreeFunction;
    };
}