# nix & nixOS Configuration / Linux Config
My reproducible nix Configuration & other configuration files.
More Documentation for myself about nixOS in my [TechNotes Repo](https://github.com/Yeshey/TechNotes).

## Credits

- Highly Inspiered by [Matthias Benaets](https://github.com/MatthiasBenaets) [configuration](https://github.com/MatthiasBenaets/nixos-config) and his [video](https://www.youtube.com/watch?v=AGVXJ-TIv3Y)

## To-Do

- Speak with teh surface kernel guys
- Make a desktop entry for MS whiteboard
  - https://discourse.nixos.org/t/create-desktop-files-with-home-manager/22261

  - MS WhiteBoard: https://whiteboard.office.com

- Make system.autoUpgrade not make PC unusable:
  - https://discourse.nixos.org/t/system-autoupgrade-nearly-halts-my-system-even-though-nixos-rebuild-doesnt/23820

- Have a way to run `nixos-rebuild` with very low priority, and using low memory. not just `sudo nice -n 19 nixos-rebuild switch`, maybe use cgroups
  - Super low cgroup priority in nixOS? https://unix.stackexchange.com/questions/44985/limit-memory-usage-for-a-single-linux-process

- Make PDF unite Work in nixOS

## Issues

- Thermald service not working correct
  - [services.thermald.configFile option always ignored due to --adaptive flag](https://github.com/NixOS/nixpkgs/issues/201402)
- nixOS LBRY not launching