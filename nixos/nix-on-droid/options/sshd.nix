{ config
, lib
, pkgs
, ...
}:

let
  # utility functions
  concatLines = list: builtins.concatStringsSep "\n" list;

  prefixLines = mapper: list: concatLines (map mapper list);

  # could be put in the config
  configPath = "ssh/sshd_config";

  keysFolder = "/etc/ssh";

  authorizedKeysFolder = "/etc/ssh/authorized_keys.d";

  supportedKeysTypes = [
    "rsa"
    "ed25519"
  ];

  sshd-start-bin = "sshd-start";

  # real config
  cfg = config.services.openssh;

  pathOfKeyOf = type: "${keysFolder}/ssh_host_${type}_key";

  generateKeyOf = type: ''
    ${pkgs.openssh}/bin/ssh-keygen \
      -t "${type}" \
      -f "${pathOfKeyOf type}" \
      -N ""
  '';

  generateKeyWhenNeededOf = type: ''
    if [ ! -f ${pathOfKeyOf type} ]; then
      mkdir --parents ${keysFolder}
      ${generateKeyOf type}
    fi
  '';

  appendAuthorizedKeysFiles = authorizedKeysFile: "cat ${authorizedKeysFile} >${authorizedKeysFolder}/${config.user.userName}";

  sshd-start = pkgs.writeScriptBin sshd-start-bin ''
    #!${pkgs.runtimeShell}
    ${prefixLines generateKeyWhenNeededOf supportedKeysTypes}

    if [ ! -f "${authorizedKeysFolder}/${config.user.userName}" ]; then
      mkdir --parents "${authorizedKeysFolder}"
      ${prefixLines appendAuthorizedKeysFiles cfg.authorizedKeysFiles}
    fi

    echo "Starting sshd on port ${lib.concatMapStrings toString cfg.ports} in the background"
    echo "connect with ssh nix-on-droid@<ip> -p 8022"
    ${pkgs.openssh}/bin/sshd \
      -f "/etc/${configPath}"
  '';

in
{
  options = {
    services.openssh = {
      enable = lib.mkEnableOption ''
        Whether to enable the OpenSSH secure shell daemon, which
        allows secure remote logins.
      '';

      ports = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ 22 ];
        description = lib.mdDoc ''
          Specifies on which ports the SSH daemon listens.
        '';
      };

      authorizedKeysFiles = lib.mkOption {
        type = lib.types.listOf (lib.types.oneOf [ lib.types.path lib.types.str ]);
        default = [ ];
        description = lib.mdDoc ''
          Specify the rules for which files to read on the host.

          This is an advanced option.

          These are paths relative to the host root file system or home
          directories and they are subject to certain token expansion rules.
          See AuthorizedKeysFile in man sshd_config for details.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "${configPath}".text = ''
        ${prefixLines (port: "Port ${toString port}") cfg.ports}

        AuthorizedKeysFile ${authorizedKeysFolder}/%u

        LogLevel VERBOSE
      '';
    };

    environment.packages = [
      sshd-start
      pkgs.openssh
    ];

    build.activationAfter.sshd = ''
      SERVER_PID=$(${pkgs.procps}/bin/ps -a | ${pkgs.toybox}/bin/grep sshd || true)
      if [ -z "$SERVER_PID" ]; then
        $DRY_RUN_CMD ${sshd-start}/bin/${sshd-start-bin}
      fi
    '';
  };
}
