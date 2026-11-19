{
  flake.modules.nixos.cli-tools =
    {
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages =
        with pkgs;
        [
          parted
          unstable.antigravity-hub
          unstable.antigravity-cli # agy
          unstable.antigravity-ide
          unstable.antigravity-acp
          # unstable.t3code
          unstable.codex
          unstable.opencode
          # unstable.cursor-cli
          unstable.grok-build
          # unstable.muse-code
        ]
        ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ intel-gpu-tools ];
    };
}
