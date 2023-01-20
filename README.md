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

- Make it so the surface doesn't die when you suspend it, or find an alternative to suspending it.

- Make PDF unite Work in nixOS, make t so you can run [this script](https://github.com/Yeshey/TechNotes/blob/main/techNotes.md#1121-unite)

- Can you alter mmore settings in gnome(surface) and add them to your nix configuration with dconf2nix now that you have a configuration running already? [dconf2nix github](https://github.com/gvolpe/dconf2nix)

## Issues

- Thermald service not working correct
  - [services.thermald.configFile option always ignored due to --adaptive flag](https://github.com/NixOS/nixpkgs/issues/201402)
- nixOS LBRY not launching