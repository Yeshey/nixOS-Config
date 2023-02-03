# nix & nixOS Configuration / Linux Config
My reproducible nix Configuration & other configuration files.  
More Documentation for myself about nixOS in my [TechNotes Repo](https://github.com/Yeshey/TechNotes).  
It has my personal configuration for two devices, my Lenovo Legion laptop and my MS Surface Pro 7.

## Credits

- Highly Inspiered by [Matthias Benaets](https://github.com/MatthiasBenaets) [configuration](https://github.com/MatthiasBenaets/nixos-config) and his [video](https://www.youtube.com/watch?v=AGVXJ-TIv3Y)

## To-Do

- Make system.autoUpgrade not make PC unusable(right now it grabs /etc/nixos/ configuration):
  - You made a comment [here](https://github.com/NixOS/nixpkgs/issues/77971) with your alterations to systemd service, once you know they work, give an update there

- Make it so the surface doesn't die when you suspend it, or find an alternative to suspending it.

- figure out how to add functions aliases to zsh
  - Make it so upgrade and update tries three times before giving up

- Sync things with syncthing instead of having game saves etc in the github repo

- Fix minecraft skin

## Issues

- Thermald service not working correct, now overriten, but the issue persists, here is the issue I raised:
  - [services.thermald.configFile option always ignored due to --adaptive flag](https://github.com/NixOS/nixpkgs/issues/201402)
- nixOS LBRY not launching
- When the command is not found, started getting this error message instead of helpful suggestions: `nixOS DBI connect unable to open database file` and don't know how that happened.
  - refer to: https://discourse.nixos.org/t/command-not-found-unable-to-open-database/3807/5 to fix it. 