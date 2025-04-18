# based on https://github.com/Infinidoge/nix-minecraft/blob/master/pkgs/build-support/mkTextileServer.nix
{
  callPackage,
  lib,
  writeShellScriptBin,
  gameVersion,
  jre_headless,
  loaderVersion,
  loaderDrv,
  loader ? (callPackage loaderDrv {inherit loaderVersion gameVersion jre_headless;}),
  extraJavaArgs ? "",
  extraMinecraftArgs ? "",
}:
(
  writeShellScriptBin "minecraft-server" ''
    exec ${lib.getExe jre_headless} ${extraJavaArgs} $@ @${loader}/libraries/net/minecraftforge/forge/${gameVersion}-${loaderVersion}/unix_args.txt nogui ${extraMinecraftArgs}''
)
// rec {
  pname = "minecraft-server";
  version = "${gameVersion}-forge-${loaderVersion}";
  name = "${pname}-${version}";

  passthru = {
    inherit loader;
  };
}
