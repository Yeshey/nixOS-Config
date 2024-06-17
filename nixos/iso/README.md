# Mordor

To make a bootable USB

## Running a test VM

It auto logs in, but you might want to change the password anyways: change the password of the user `yeshey` in `modules/nixos/mySystem/user.nix` in the option `users.${cfg.user}.hashedPassword` to something else so you can login.
It will share your `/nix/store`

Build the ISO with
```bash
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```
