# nix & nixOS Configuration / Linux Config
My reproducible nix Configuration & other configuration files.  
More Documentation for myself about nixOS in my [TechNotes Repo](https://github.com/Yeshey/TechNotes).  
It has my personal configuration for two devices, my Lenovo Legion laptop and my MS Surface Pro 7.

## Credits

- Highly Inspiered by [Matthias Benaets](https://github.com/MatthiasBenaets) [configuration](https://github.com/MatthiasBenaets/nixos-config) and his [video](https://www.youtube.com/watch?v=AGVXJ-TIv3Y)

## Notes

- Check the [languages-frameworks](https://github.com/NixOS/nixpkgs/tree/master/doc/languages-frameworks) if you ever want to do a project with nix in one of these programming languages

## Nvidia-GPU-Virtualisaion(nixos21.05) Brach

- Use this branch to do GPU virtualisation with my nvidia card as this repo doesn't work in 22.11 yet: https://github.com/danielfullmer/nixos-nvidia-vgpu/issues/8
- So, You need to change the channels:
  - `sudo nix-channel --add https://nixos.org/channels/nixos-21.05 nixos`
  - `sudo nix-channel --add https://nixos.org/channels/nixos-21.05 nixpkgs`
  - `sudo nix-channel --update`
  - Check with `sudo nix-channel --list`
- Go back with:
  - `sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixos`
  - `sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixpkgs`
  - `sudo nix-channel --update`
  - Check with `sudo nix-channel --list`

## To-Do

- Make system.autoUpgrade not make PC unusable(right now it grabs /etc/nixos/ configuration):
  - You made a comment [here](https://github.com/NixOS/nixpkgs/issues/77971) with your alterations to systemd service, once you know they work, give an update there
  - Fix the fail case in the autoUpgrade service, so it remocves the last version of the flake.lock if it didn't finish.

- Make it so the surface doesn't die when you suspend it, or find an alternative to suspending it.

- figure out how to add functions aliases to zsh
  - Make it so upgrade and update tries three times before giving up

## Issues

- Thermald service not working correct, now overriten, but the issue persists, here is the issue I raised:
  - [services.thermald.configFile option always ignored due to --adaptive flag](https://github.com/NixOS/nixpkgs/issues/201402)
- nixOS LBRY not launching
- When the command is not found, started getting this error message instead of helpful suggestions: `nixOS DBI connect unable to open database file` and don't know how that happened.
  - refer to: https://discourse.nixos.org/t/command-not-found-unable-to-open-database/3807/5 to fix it. 