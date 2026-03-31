{ inputs, lib, ... }:
{
  flake.modules.nixOnDroid.nix-on-droid =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.modules.nixOnDroid.sshd
      ];

      android-integration.am.enable = true;
      android-integration.termux-open-url.enable = true;
      android-integration.xdg-open.enable = true;

      environment.packages = with pkgs; [
        tmux wget tree git
      ];

      home-manager.config =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            # system-cli
            system-cli
            system-default
            system-minimal

            # shell
            # starship
            # direnv
            # cli-tools
            # nh
            # nix-index-database
            # nix-your-shell
            # gc
          ];

          programs.git = {
            enable = true;
            settings.user.name  = "Yeshey";
            settings.user.email = "yesheysangpo@hotmail.com";
            signing.format = null;
          };
          programs.zsh = {
            enable = true;
            shellAliases = {
              update = lib.mkForce "rm -rf ~/.cache/nix && nix-on-droid switch --flake github:Yeshey/nixOS-Config#nix-on-droid";
              clean  = lib.mkForce "nix-collect-garbage -d && nix-store --gc && echo 'Displaying stray roots:' && nix-store --gc --print-roots | egrep -v '^(/nix/var|/run/current-system|/run/booted-system|/proc|\\{memory|\\{censored)'";
            };
            initContent = lib.mkBefore ''
              sshd-start
            '';
          };
          home.activation.storageSymlink = ''
            ln -sfn /storage/emulated/0 $HOME/storage
          '';
          home.enableNixpkgsReleaseCheck = false;
          home.stateVersion = "24.05";
        };

      user.shell = "${pkgs.zsh}/bin/zsh";
      system.stateVersion = "24.05";
    };
}