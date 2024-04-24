# nix & nixOS Configuration / Linux Config
The spiciest config on the market 😳🥵💦

My reproducible nix Configuration & other configuration files.  
More Documentation for myself about nixOS in my [TechNotes Repo](https://github.com/Yeshey/TechNotes).  
It has my personal configuration for two devices, my Lenovo Legion laptop and my MS Surface Pro 7.

## Credits

- Initially Inspiered by [Matthias Benaets](https://github.com/MatthiasBenaets) [configuration](https://github.com/MatthiasBenaets/nixos-config) and his [video](https://www.youtube.com/watch?v=AGVXJ-TIv3Y);
- Derived from [LongerHV's](https://github.com/LongerHV) [nixos-configuration](https://github.com/LongerHV/nixos-configuration/tree/master);
- Based on [Misterio77's](https://github.com/Misterio77) [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs);
- Inspiered by [pinage404](https://gitlab.com/pinage404) [dotfiles](https://gitlab.com/pinage404/dotfiles)

Do something like this
Special Thanks
wlroots - For their amazing library
tinywl - For showing how 2 do stuff
Sway - For showing how 2 do stuff the overkill way
Vivarium - For showing how 2 do stuff the simple way
dwl - For showing how 2 do stuff the hacky way
Wayfire - For showing how 2 do some graphics stuff
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

- change the files you create with home manager to create with this:
  ```
    systemd.tmpfiles.rules = [
      "d /var/spool/samba 1777 root root -"
    ];
  ```
  When appropriate. For example for syncthing. (seen this is possible in [this answer](https://discourse.nixos.org/t/nixos-configuration-for-samba/17079))

- Adding support for one virtual screen, so you can use another computer as a second screen with `deskreen`

- Make system.autoUpgrade not make PC unusable(right now it grabs /etc/nixos/ configuration):
  - You made a comment [here](https://github.com/NixOS/nixpkgs/issues/77971) with your alterations to systemd service, once you know they work, give an update there
  - Fix the fail case in the autoUpgrade service, so it remocves the last version of the flake.lock if it didn't finish.

- Make it so the surface doesn't die when you suspend it, or find an alternative to suspending it.

- figure out how to add functions aliases to zsh
  - Make it so upgrade and update tries three times before giving up?

## Notes

[This answer:](https://discourse.nixos.org/t/nixos-configuration-for-samba/17079) 
- For creating folders, there is [systemd.tmpfiles](https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=systemd.tmpfiles). Despite the implications of its name, you can use it to automatically ensure folders exist, without setting up any clean up. Looks something like this in my config:

  ```nix
  systemd.tmpfiles.rules = [
    "d /mnt/media/Movies 0770 media media - -"
  ];
  ```

- If you want to have a systemd service that can change files in your system, here is an example, weites to /my-ip file your local IP:
  ```nix
    systemd.services.my-awesome-service = {
      description = "writes a file to /my-ip";
      serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        ${pkgs.busybox}/bin/ip a | grep "scope" | grep -Po '(?<=inet )[\d.]+' | head -n 2 | tail -n 1 > /my-ip;
        echo "success!"
      '';
      wantedBy = [ "multi-user.target" ]; # starts after login
    };
  ```

- For normal Unix passwords, I just set them imperatively after installation.

More generally, you can do imperative things when activating a new NixOS configuration using [system.activationScripts](https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=system.activationScripts). Of course, the script you run should be idempotent and such changes would not be able to be rolled-back by standard NixOS mechanisms - imperative is imperative.

## Issues

- Thermald service not working correct, now overriten, but the issue persists, here is the issue I raised:
  - [services.thermald.configFile option always ignored due to --adaptive flag](https://github.com/NixOS/nixpkgs/issues/201402)
- nixOS LBRY not launching
- When the command is not found, started getting this error message instead of helpful suggestions: `nixOS DBI connect unable to open database file` and don't know how that happened.
  - refer to: https://discourse.nixos.org/t/command-not-found-unable-to-open-database/3807/5 to fix it. 