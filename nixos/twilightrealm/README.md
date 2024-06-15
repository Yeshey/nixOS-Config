# Mordor

My VM tests machine

## Running a test VM

Change the password of the user `yeshey` in `modules/nixos/mySystem/user.nix` in the option `users.${cfg.user}.hashedPassword` to something else so you can login.
It will share your `/nix/store`

```bash
nixos-rebuild build-vm --flake .#twilightrealm
result/bin/run-nixos-twilightrealm-vm

# Remove disk image after you are done
rm twilightrealm.qcow2
```
