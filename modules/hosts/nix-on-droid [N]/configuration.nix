{ inputs, lib, ... }:
{
  flake.modules.nixOnDroid.nix-on-droid =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixOnDroid; [
        sshd-droid
        autossh-reverse-proxy-droid
      ];

      android-integration.am.enable = true;
      android-integration.termux-open-url.enable = true;
      android-integration.xdg-open.enable = true;

      environment.packages = with pkgs; [
        tmux wget curl tree git 
        htop nix-output-monitor
        procps diffutils findutils util-linux
        zip unzip gnutar gzip xz
        gnugrep gnused nano
        devenv ookla-speedtest
      ];

      home-manager.config =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            standalone-hm
            # system-cli

            nvix
            shell
            ssh
            starship
            direnv
            nh
            nix-index-database
            nix-your-shell
            gc
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
              update-remote = lib.mkForce "nix-on-droid switch --flake github:Yeshey/nixOS-Config#nix-on-droid --max-jobs 1 --option 'experimental-features' 'nix-command flakes pipe-operators' -v |& ${pkgs.nix-output-monitor}/bin/nom";
              update = lib.mkForce "echo 'updating from local .setup...' && nix-on-droid switch --flake $HOME/.setup#nix-on-droid --max-jobs 1 --option 'experimental-features' 'nix-command flakes pipe-operators' -v |& ${pkgs.nix-output-monitor}/bin/nom";
              clean  = lib.mkForce "nix-collect-garbage -d && nix-store --gc && echo 'Displaying stray roots:' && nix-store --gc --print-roots | egrep -v '^(/nix/var|/run/current-system|/run/booted-system|/proc|\\{memory|\\{censored)'";
            };
            initContent = lib.mkBefore ''
              echo "Welcome to your shell!"
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