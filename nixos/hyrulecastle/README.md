# Mordor

My dailydriver

## Running a test VM

Change the password of the user `yeshey` in `modules/nixos/mySystem/user.nix` in the option `users.${cfg.user}.hashedPassword` to something else so you can login.

```bash
nixos-rebuild build-vm --flake .#hyrulecastle
result/bin/run-hyrulecastle-vm

# Remove disk image after you are done
rm hyrulecastle.qcow2
```
