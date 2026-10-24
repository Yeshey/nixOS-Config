{ pkgs, lib, ... }:
let
  scriptsDir = ./scripts;
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

  home-manager.users.openclaw.programs.openclaw.config.skills.load.extraDirs = [
    "/home/openclaw/projects/nixOS-Config/modules/services/hosting/openclaw [n]/_playground/skills"
  ];
}