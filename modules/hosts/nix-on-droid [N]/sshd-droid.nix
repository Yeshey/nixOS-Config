{ inputs, ... }:
{
  flake.modules.nixOnDroid.sshd-droid =
    { config, lib, pkgs, ... }:
    let
      concatLines = list: builtins.concatStringsSep "\n" list;
      prefixLines = mapper: list: concatLines (map mapper list);

      configPath = "ssh/sshd_config";
      keysFolder = "/etc/ssh";
      authorizedKeysFolder = "/etc/ssh/authorized_keys.d";
      supportedKeysTypes = [ "rsa" "ed25519" ];
      sshd-start-bin = "sshd-start";
      ports = [ 8022 ];
      authorizedKeysFiles = [ ./../../../id_ed_mykey.pub ];

      pathOfKeyOf = type: "${keysFolder}/ssh_host_${type}_key";

      generateKeyWhenNeededOf = type: ''
        if [ ! -f ${pathOfKeyOf type} ]; then
          mkdir --parents ${keysFolder}
          ${pkgs.openssh}/bin/ssh-keygen -t "${type}" -f "${pathOfKeyOf type}" -N ""
        fi
      '';

      appendAuthorizedKeysFiles = authorizedKeysFile:
        "cat ${authorizedKeysFile} >${authorizedKeysFolder}/${config.user.userName}";

      sshd-start = pkgs.writeScriptBin sshd-start-bin ''
        #!${pkgs.runtimeShell}
        ${prefixLines generateKeyWhenNeededOf supportedKeysTypes}

        mkdir --parents "${authorizedKeysFolder}"
        ${prefixLines appendAuthorizedKeysFiles authorizedKeysFiles}

        echo "Starting sshd on port ${lib.concatMapStrings toString ports} in the background"
        echo "connect with ssh nix-on-droid@<ip> -p 8022"
        ${pkgs.openssh}/bin/sshd -f "/etc/${configPath}"
      '';
    in
    {
      home-manager.config =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            sshd-droid
          ];
        };

      environment.etc."${configPath}".text = ''
        ${lib.concatMapStrings (port: "Port ${toString port}\n") ports}
        AuthorizedKeysFile ${authorizedKeysFolder}/%u

        PubkeyAuthentication yes
        PasswordAuthentication no
        StrictModes no
      '';

      environment.packages = [
        sshd-start
        pkgs.openssh
      ];

      build.activationAfter.sshd = ''
        if ! ${pkgs.procps}/bin/pgrep -x sshd > /dev/null 2>&1; then
          $DRY_RUN_CMD ${sshd-start}/bin/${sshd-start-bin}
        fi
      '';
    };
  flake.modules.homeManager.sshd-droid =
    { pkgs, lib, ... }:
    {
      programs.zsh.initContent = lib.mkBefore ''
        ${pkgs.procps}/bin/pgrep -x sshd > /dev/null 2>&1 || sshd-start
      '';
    };
}