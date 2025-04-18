# based on:
# - https://github.com/Infinidoge/nix-minecraft/blob/ab4790259bf8ed20f4417de5a0e5ee592094c7c3/pkgs/fabric-servers/default.nix
# - https://github.com/Faeranne/nix-minecraft/blob/f4e4514f1d65b6a19704eab85070741e40c1d272/pkgs/forge-servers/default.nix
{
  callPackage,
  lib,
  jre8_headless,
  jre_headless,
}:
with lib; let
  loader_versions = lib.importJSON ./lock_launcher.json;

  # Older Minecraft versions that were written for Java 8, required Java 8.
  # Mojang has since rewritten a lot of their codebase so that Java versions
  # are no longer as important for stability as they used to be. Meaning we can
  # target latest the latest JDK for all newer versions of Minecraft.
  # TODO: Assert that jre_headless >= java version
  getJavaVersion = v:
    if v == 8
    then jre8_headless
    else jre_headless;

  # Copied from https://github.com/Infinidoge/nix-minecraft/blob/ab4790259bf8ed20f4417de5a0e5ee592094c7c3/lib/default.nix
  chain = {
    func = id;
    __functor = self: input:
      if (typeOf input) == "lambda"
      then self // {func = e: input (self.func e);}
      else self.func input;
  };

  escapeVersion = replaceStrings ["." " "] ["_" "_"];

  isNormalVersion = v: isList (match "([[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?)" v);

  latestVersion = versions:
    chain
    (filter isNormalVersion)
    (sort versionOlder)
    last
    (attrNames versions);
  #####

  mkServer = gameVersion: (callPackage ./server.nix {
    inherit gameVersion;
    loaderVersion = latestVersion loader_versions.${gameVersion};
    # TODO: More mature way to choose Java Version
    jre_headless = getJavaVersion 17;
    loaderDrv = ./derivation.nix;
    extraJavaArgs = "-Dlog4j.configurationFile=${./log4j.xml}";
  });

  gameVersions = attrNames loader_versions;

  packagesRaw = lib.genAttrs gameVersions mkServer;
  packages = lib.mapAttrs' (version: drv: nameValuePair "forge-${escapeVersion version}" drv) packagesRaw;
in
  packages
