{
  config,
  lib,
  pkgs,
  ...
}:
let
  CONTAINS_NEWLINE_RE = ".*\n.*";
  # The following values are reserved as complete option values:
  # { - start of a group.
  # """ - start of a multi-line string.
  RESERVED_VALUE_RE = "[[:space:]]*(\"\"\"|\\{)[[:space:]]*";
  NEEDS_MULTILINE_RE = "${CONTAINS_NEWLINE_RE}|${RESERVED_VALUE_RE}";

  # There is no way to encode """ on its own line in a Minetest config.
  UNESCAPABLE_RE = ".*\n\"\"\"\n.*";

  toConfMultiline =
    name: value:
    assert lib.assertMsg (
      (builtins.match UNESCAPABLE_RE value) == null
    ) ''""" can't be on its own line in a minetest config.'';
    "${name} = \"\"\"\n${value}\n\"\"\"\n";

  toConf = values:
    lib.concatStrings (
      lib.mapAttrsToList (
        name: value:
        {
          bool = "${name} = ${toString value}\n";
          int = "${name} = ${toString value}\n";
          null = "";
          set = "${name} = {\n${toConf value}}\n";
          string =
            if (builtins.match NEEDS_MULTILINE_RE value) != null then
              toConfMultiline name value
            else
              "${name} = ${value}\n";
        }.${builtins.typeOf value}
      ) values
    );

  flag = val: name: lib.optionals (val != null) ["--${name}" (toString val)];
in {
  options.services.mineclonia-server = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable this Mineclonia server instance.";
        };

        gameId = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Game ID to use (run 'minetestserver --gameid list' for options)";
        };

        world = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "World directory to use";
        };

        configPath = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to custom config file";
        };

        config = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
          description = "Configuration settings (ignored if configPath is set)";
        };

        logPath = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to log file (null for stdout)";
        };

        port = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          description = "Port to listen on (default: 30000)";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional command-line arguments";
        };
      };
    });
    default = {};
    description = "Multiple Mineclonia server instances";
  };

  config = let
    cfg = config.services.mineclonia-server;
    enabledInstances = lib.filterAttrs (_: ic: ic.enable) cfg;
  in lib.mkIf (enabledInstances != {}) {
    systemd.services = lib.mapAttrs' (name: instanceCfg: {
      name = "mineclonia-server-${name}";
      value = {
        description = "Mineclonia Server Instance: ${name}";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];

        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "mineclonia-${name}"; # will be /var/lib/mineclonia-${name}
          Restart = "always";
          WorkingDirectory = "/var/lib/mineclonia-${name}";
        };
        environment = {
          HOME = "/var/lib/mineclonia-${name}";
        };

        script = let
          flags = [
              "--server"
            ]
            ++ (if instanceCfg.configPath != null then [
              "--config" instanceCfg.configPath
            ] else [
              "--config" (builtins.toFile "minetest-${name}.conf" (toConf instanceCfg.config))
            ])
            ++ (flag instanceCfg.gameId "gameid")
            ++ (flag instanceCfg.world "world")
            ++ (flag instanceCfg.logPath "logfile")
            ++ (flag instanceCfg.port "port")
            ++ instanceCfg.extraArgs;
        in ''
          cd "$STATE_DIRECTORY"
          exec ${pkgs.minetest}/bin/minetest ${lib.escapeShellArgs flags}
        '';
      };
    }) enabledInstances;
  };
}