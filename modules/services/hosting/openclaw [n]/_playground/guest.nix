{ pkgs, lib, ... }:
let
  scriptsDir = ./scripts;
  mcpDir = ./mcp;
  # Every regular .sh file in scripts/ becomes a command named after the
  # file with the .sh suffix removed. Uses writeScriptBin (not
  # writeShellScriptBin) so the scripts' own #!/usr/bin/env bash is kept.
  scriptFiles = lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".sh" name)
    (builtins.readDir scriptsDir);
  mkScript = name:
    pkgs.writeScriptBin
      (lib.removeSuffix ".sh" name)
      (builtins.readFile (scriptsDir + "/${name}"));

  # Every regular .py file in mcp/ becomes an MCP stdio server named after
  # the file. Each file is a standalone `uv run --script` (PEP 723 deps).
  mcpFiles = lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".py" name)
    (builtins.readDir mcpDir);
in
{
  # imports = [ ./litellm-test.nix ];  # disabled after test
  sops.secrets.opencode_key = {
    owner = "openclaw";
    mode = "0400";
  };
  environment.systemPackages = [
    pkgs.cowsay
    pkgs.cmatrix
  ] ++ lib.mapAttrsToList (name: _: mkScript name) scriptFiles;

  home-manager.users.openclaw.programs.openclaw.config = {
    skills.load.extraDirs = [
      "/home/openclaw/projects/nixOS-Config/modules/services/hosting/openclaw [n]/_playground/skills"
    ];
    mcp.servers = lib.mapAttrs'
      (name: _: lib.nameValuePair (lib.removeSuffix ".py" name) {
        command = "uv";
        args = [ "run" "--script" "${mcpDir}/${name}" ];
      })
      mcpFiles;
  };
}