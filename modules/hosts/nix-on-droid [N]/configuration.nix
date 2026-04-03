# For background processes to not be killed you might need to take a look here: https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md#internal-details-for-android-14-and-higher
# try on the PC before you do on the phone: nix build --impure .#nixOnDroidConfigurations.nix-on-droid.activationPackage
{ inputs, lib, ... }:
{
  flake.modules.nixOnDroid.nix-on-droid =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixOnDroid; [
        sshd-droid
        autossh-reverse-proxy-droid

        # root-droid # breaks the install
      ];

      android-integration.am.enable = true;
      android-integration.termux-open-url.enable = true;
      android-integration.xdg-open.enable = true;

      environment.packages = with pkgs; [
        wget curl tree git 
        htop nix-output-monitor
        procps diffutils findutils util-linux
        zip unzip gnutar gzip xz
        gnugrep gnused nano
        devenv ookla-speedtest
      ];

      # font that supports starship theme
      terminal.font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";

      home-manager.config =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            standalone-hm
            # system-cli

            zed-editor-host
            nvix
            tmux
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
              update-remote = lib.mkForce "nix-on-droid switch --flake github:Yeshey/nixOS-Config#nix-on-droid --max-jobs 2 --option 'experimental-features' 'nix-command flakes pipe-operators' -v |& ${pkgs.nix-output-monitor}/bin/nom";
              update = lib.mkForce "echo 'updating from local .setup...' && nix-on-droid switch --flake $HOME/.setup#nix-on-droid --max-jobs 2 --option 'experimental-features' 'nix-command flakes pipe-operators' -v |& ${pkgs.nix-output-monitor}/bin/nom";
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