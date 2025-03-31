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
          # ssh public key of my_identity key
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop"
          # Temporary giveaway key – copy the entire content from ~/.ssh/temp.pub:
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6NKdSPrgQpWWAwoNXwFoOaudUOG5f7alfSiNzMMcF/ Temporary giveaway key"
        ];
        # shell = pkgs.bash;
        #useDefaultShell = false;

        # generated with `diceware -w en_eff` and hashed using `mkpasswd --method=sha-512 --rounds=2000000`
        # Works, but is it safe?
        hashedPassword = "$6$rounds=2000000$/pvZKZOnJE51jPnR$FDiOHyOvkouz36fW8MLiPYOFdEYf/SknZWVc9tqV039bOEvQMfH9TsezvITcbsMwqVHFzA0uEPwS0msabEUKg1";
      };
      users.root = {
        openssh.authorizedKeys.keys = [
          # ssh public key of my_identity key
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop"
        ];
      };
    };
  };
}
