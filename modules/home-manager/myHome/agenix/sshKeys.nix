{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.myHome.agenix.sshKeys;
in
{
  options.myHome.agenix.sshKeys = with lib; {
    enable = mkEnableOption "sshKeysHome";
  };

  config = lib.mkIf cfg.enable {

    # puts my_identity private and public keys in root folder
    home.file.".ssh/my_identity.pub".text = ''
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop
    '';
    # home.file.".ssh/my_identitytest".source = builtins.toPath "${fullPath}/bin/fullPath"; # doesnt work :(
    systemd.user.services."sshKeysYeshey" = let 
      mystuff = pkgs.writeShellScriptBin "echo-secret" ''
            ${pkgs.coreutils}/bin/cat ${config.age.secrets.my_identity_yeshey.path} > /home/yeshey/.ssh/my_identity

            chmod 700 ~/.ssh
            chmod 600 ~/.ssh/*
          '';
    in {
      Unit = {
        Description = "sshKeysYeshey";
        After = [ "agenix.service" ];
        Require = [ "agenix.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mystuff}/bin/echo-secret";
      };
      Install.WantedBy = [ "default.target" ];
    };

  };
}
