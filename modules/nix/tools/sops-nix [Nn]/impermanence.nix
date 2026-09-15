{ inputs, ... }:
{
  flake.modules.nixos.sops-nix =
    { config, ... }:
    {
      # Host key must survive AND be restored before anything reads it —
      # path being "persisted" isn't enough if it's remounted too late.
      fileSystems."/etc/ssh".neededForBoot = true;

      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            # safety net only — unused while age.sshKeyPaths is set,
            # but harmless to persist in case generateKey ever kicks in
            "/var/lib/sops-nix"
          ];
        };
      };
    };
}