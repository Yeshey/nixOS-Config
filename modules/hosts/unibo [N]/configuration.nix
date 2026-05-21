{ inputs, lib, ... }:
let
  username = "joaofilipe.silvade";
  scr      = "/scratch.hpc/${username}";
in
{
  flake.modules.homeManager.unibo =
    { pkgs, config, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        standalone-hm
        tmux
        shell
        ssh
        starship
        direnv
        nix-index-database
        nix-your-shell
        gc
        # omitted: zed-editor-host nvix nh (GUI/host-specific, won't build on cluster)
      ];

      home.username    = username;
      home.homeDirectory = lib.mkForce scr;

      # standalone-hm hardcodes yeshey — override
      programs.zsh.shellAliases.update = lib.mkForce
        "home-manager switch --flake ${scr}/.setup#unibo";

      # standalone-hm's nix.enable=true is fine: HM writes nix.conf to $SCR/.config/nix/
      # After first switch, nix from HM profile replaces nix-portable
      nix.extraOptions = lib.mkForce ''
        !include ./extra.conf
        store = ${scr}/.nix/store
      '';
    };
}