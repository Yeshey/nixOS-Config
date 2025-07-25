{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem;
in
{
  options.mySystem = {
    user = lib.mkOption {
      default = "yeshey";
      type = lib.types.str;
    };
    home-manager = {
      enable = lib.mkEnableOption "home-manager";
      home = lib.mkOption {
        default = ../../../home-manager;
        type = lib.types.path;
      };
    };
  };

  config = {
    home-manager = lib.mkIf cfg.home-manager.enable {
      backupFileExtension = lib.mkOverride 1010 "backup"; # let hm overwrite files (https://nix-community.github.io/home-manager/nixos-options.xhtml#nixos-opt-home-manager.backupFileExtension)
      useGlobalPkgs = lib.mkOverride 1010 true;
      useUserPackages = lib.mkOverride 1010 true;
      extraSpecialArgs = {
        inherit inputs;
      };
      sharedModules = builtins.attrValues outputs.homeManagerModules;
      users."${cfg.user}" = import cfg.home-manager.home;
    };
    users = {
      # defaultUserShell = pkgs.zsh;
      users.${cfg.user} = {
        isNormalUser = true;
        # extraGroups = [ "wheel" "networkmanager" "keys" ]; # TODO
        extraGroups = [
          "scanner"
          "networkmanager"
          "wheel"
          "dialout"
          "docker"
          "adbusers"
          "libvirtd"
          "surface-control"
          "audio"
          "tss" # For TPM access
          "input" # For https://github.com/kokoko3k/ssh-rdp
        ]; # TODO if you ever extend the module to be able to have several users, you need to see how to handle this
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGlaGOK+qN0/Fk0d2bVdRTNncfQwxaEofoOnKgwK95s"
        ];
        # shell = pkgs.bash;
        #useDefaultShell = false;

        # generated with `diceware -w en_eff` and hashed using `mkpasswd --method=sha-512 --rounds=2000000`
        # Works, but is it safe?
        hashedPassword = "$6$rounds=2000000$/pvZKZOnJE51jPnR$FDiOHyOvkouz36fW8MLiPYOFdEYf/SknZWVc9tqV039bOEvQMfH9TsezvITcbsMwqVHFzA0uEPwS0msabEUKg1";
      };
      users.root = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGlaGOK+qN0/Fk0d2bVdRTNncfQwxaEofoOnKgwK95s"
        ];
      };
    };
  };
}
