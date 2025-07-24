# nix & nixOS Configuration / Linux Config
The spiciest config on the market [😳🥵💦](https://matias.me/nsfw/)

My reproducible nix Configuration & other configuration files.  
More Documentation (for myself) about nixOS in my [TechNotes Repo](https://github.com/Yeshey/TechNotes).  

It has my personal configuration for my Lenovo Legion laptop(`hyrulecastle`), my MS Surface Pro 7(`kakariko`) and my Oracle `aarch64` server(`skyloft`).

## Installing on a new computer

- You might need to create the home manager folder manually `mkdir ~/.local/state/nix/profiles`

- Yo'll have to find the syncthing ID by going to http://127.0.0.1:8384, getting the ID, and adding it in the syncthing config

- You'll have to add the new machine public key to the secrets for agenix with `cat /etc/ssh/ssh_host_rsa_key.pub` and add it in the `secrets/secrets.nix` and rekey the keys `cd ~/.setup/secrets` and `agenix --rekey`.

- Right click on wastebin and configure to delete trash after 7 days, still don't know how to declare this.

- For remote backups, I'm using OneDrive with rclone, you will have to add the rclone remote with `rclone config` either as yeshey (for hyrulecastle) or as root (for skyloft) and set the name of the remote to `OneDriverISCTE`.

- nix-on-droid: (don't forget you can connect your phone to the PC and control it with something like `scrcpy --legacy-paste`) install my flake in app by adding [the normal packages](https://nix-on-droid.unboiled.info/upgrade.txt) (restart `nix-on-droid` after that) and running `nix-shell -p git --run "nix-on-droid --flake github:Yeshey/nixOS-Config#nix-on-droid switch"`. (or use the `/nix-on-droid` branch if it isn't working)
  You'll have to find a way to send the ssh keys, `scp` isn't working, if you have root you can do this:
  - You can run a server on the localnetwork to serve the files: `nix-shell --pure -p python310 --run "cd /home/yeshey/.ssh && python3 -m http.server 8000"`, you might nee to turn off the firewall (`networking.firewall.enable = false;`). And From `termux`, not `nix-on-droid`, run:
    - `su`, to get into the root user, to change files in other apps. Change the ip as needed:
    - ```sh
      export server="http://10.61.0.104:8000" && mkdir -p /data/data/com.termux.nix/files/home/.ssh && curl -o /data/data/com.termux.nix/files/home/.ssh/my_identity $server/my_identity && curl -o /data/data/com.termux.nix/files/home/.ssh/my_identity.pub $server/my_identity.pub && curl -o /data/data/com.termux.nix/files/home/.ssh/config $server/config && mkdir -p /data/data/com.termux/files/home/.ssh && curl -o /data/data/com.termux/files/home/.ssh/my_identity $server/my_identity && curl -o /data/data/com.termux/files/home/.ssh/my_identity.pub $server/my_identity.pub && curl -o /data/data/com.termux/files/home/.ssh/config $server/config
      ```
    - Confirm with:
      ```sh
      ls /data/data/com.termux.nix/files/home/.ssh
      ```
      and
      ```sh
      ls /data/data/com.termux/files/home/.ssh
      ```
  - To use `nix-on-droid` with root, you can try taking a look [here](https://github.com/nix-community/nix-on-droid/issues/3)
  - If you want to add a [termux:widget](https://github.com/termux/termux-widget) to connect to your computers with their reverse proxy to the server (can be enabled with [autosshReverseProxy](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/autosshReverseProxy.nix)) you can add to `~/.shortcuts/` these files:
    - `connectHyruleCastle`:
      ```sh
      ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@143.47.53.175 "ssh -t -p 2232 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@localhost"
      ```
    - `connectKakariko`:
      ```sh
      ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@143.47.53.175 "ssh -t -p 2233 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@localhost"
      ```
    - `connectSkyloft`:
      ```sh
      ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@143.47.53.175
      ```
    - From your phone, you can redirect port 2998 of your PC to http://localhost:2998 on your phone with `ssh -L 2998:localhost:2998 -J yeshey@143.47.53.175 yeshey@localhost -p 2232`

  - If you get rate limitted, you can use authenticated requests:
    - `gh auth login`
    - `sudo nixos-rebuild --flake ~/.setup#hyrulecastle --option cores 6 --option max-jobs 3 switch --option access-tokens "github.com=$(gh auth token)"`

### Non-NixOS Home-manager standalone with flakes

1. Install nix, follow [hm standalone](https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone). (These instructions assume system wide installation)
2. `mkdir ~/.setup ; git clone git@github.com:Yeshey/nixOS-Config.git ~/.setup/ --depth 1`
3. Follow [flakes Standalone setup](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone), and use `nix run home-manager/master -- init --switch /home/yeshey/.setup` to set up the hm in the right place.
4. `home-manager switch --flake ~/.setup#yeshey` to activate the configuration
5. Set zsh shell as default:   
   `echo "/home/$USER/.nix-profile/bin/zsh" | sudo tee -a /etc/shells`  
   `chsh -s "/home/$USER/.nix-profile/bin/zsh" "$USER"`

## Credits

- Initially introduced to nix and nixOS by [Kylix](https://github.com/kylixafonso) 👀
- First iteration inspiered by [Matthias Benaets'](https://github.com/MatthiasBenaets) [configuration](https://github.com/MatthiasBenaets/nixos-config) and his [video](https://www.youtube.com/watch?v=AGVXJ-TIv3Y);
- Derived from [LongerHV's](https://github.com/LongerHV) [nixos-configuration](https://github.com/LongerHV/nixos-configuration/tree/master);
- Based on [Misterio77's](https://github.com/Misterio77) [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs);
- Inspiered by [pinage404](https://gitlab.com/pinage404) [dotfiles](https://gitlab.com/pinage404/dotfiles)
- (Furure?/To-Do) Looking into [mightyiam's](https://github.com/mightyiam) [config](https://github.com/mightyiam/infra)

## Highlights:

- **Structure** 
    - Separation of home manager, nixOS system configuration and Host services through a myHome and mySystem and toHost modules, this way it could also be deployed on a home-manager only system the same way [LongerHV's](https://github.com/LongerHV) [nixos-configuration](https://github.com/LongerHV/nixos-configuration/tree/master) is set up;

    - Unstable packages available at `pkgs.unstable.<package>`, [NUR](https://github.com/nix-community/NUR) packages available at `pkgs.nur.<package>` using overlays. Check [Misterio77's](https://github.com/Misterio77) `standard` [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) for getting started with this structure.

- **Auto Upgrades On Shutdown** - Setting auto upgrades on my desktop PC only on shutdown once every week: [autoUpgradesOnShutdown.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/autoUpgradesOnShutdown.nix);

- **Syncthing** - Declaratively set syncthing, including ignore patterns with `userActivationScripts` (TODO: set syncthing as a home manager service): [syncthing.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/syncthing.nix);

- ~~**LUKS on LVM with LVM cache**~~ **bcacheFS as root ( ͡° ͜ʖ ͡°)** - across microSD (background_target) and NVME (foreground_target and promote_target) on `kakariko`: [boot.nix](https://github.com/Yeshey/nixOS-Config/blob/main/nixos/kakariko/boot.nix);

- **clean** - `clean` is an alias for a script that cleans user and system dangling nix packages, optimises the store, uninstalls unused Flatpak packages, and removes dangling docker and podman images, volumes and networks: for [`myHome`](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/myScripts.nix) and for [`mySystem`](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/autoUpgradesOnShutdown.nix)

- **pci-passthrough** - for passing my `NVIDIA GeForce RTX 2060 Mobile` to a virt-manager VM and using my intel processor for the host: [pci-passthrough.nix](https://github.com/Yeshey/nixOS-Config/blob/main/nixos/hyrulecastle/pci-passthrough.nix), but better yet:

- **VGPU** - Unlocked VGPU functionality on my consumer nvidia card: [vgpu.nix](https://github.com/Yeshey/nixOS-Config/blob/main/nixos/hyrulecastle/vgpu.nix). Using my module, more details there: [nixos-nvidia-vgpu](https://github.com/Yeshey/nixos-nvidia-vgpu);

- **Ollama with open-webui and searx** - Ollama and Open-WebUI can be activated with a single module: [ollama](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/toHost/ollama.nix). If searx, to use your own search engine, is also activated, models on openweb-ui are able to search the internet through it: [searx](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/toHost/searx.nix)

- **i2p firefox profile** - Home manager auto creates a firefox profile able to access the hidden i2p net when `services.i2p.enable` is enabled on the host, and makes a `.desktop` file for easy access, `i2pFirefoxProfile` option: [firefox.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/homeApps/firefox.nix);

- **Safe-rm** - I nuked my PC once by running `sudo rm -r /*` instead of `sudo -r rm ./*`, so I decided to change all my `rm` calls to `safe-rm` calls through changing the binary and adding aliases, both in `myHome`: [safe-rm.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/safe-rm.nix); and in `mySystem`: [safe-rm.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/safe-rm.nix);

- **OneDriver** - home-manager module for [onedriver](https://github.com/jstaf/onedriver) that auto clears cache every month, of course: [onedriver.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/onedriver.nix).

- **Substituters** - Uses a bunch of substituters for extra caches to hopefully make rebuilds faster: [default.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/default.nix). Also in my module to activate when home manager is used standalone (untested): [non-nixos.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/non-nixos.nix);

- **Agenix** - Using [agenix](https://github.com/ryantm/agenix) both at system (`mySystem` - [default.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/agenix/default.nix)):  and at user (`myHome` - [default.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/agenix/default.nix)) levels, they grab secrets from `/secrets`.

- **VSCodium** - Visual Studio Codium, the open source version of VSC, configuration settings propagated to appropriate locations for VScodium, VSCode and openvscode-server, has a bunch of extensions and configuration for latex nix language server, settings for special characters to work with starship theme in terminal, java, etc: [vscodium/default.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/homeApps/vscodium/default.nix)

- **piper-tts as Text to Speach** - A single english voice, instead of the robotic default voice: [piperTextToSpeech.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/piperTextToSpeech.nix)

## Gallery

### HyruleCastle

![hyrulecastle](https://github.com/Yeshey/nixOS-Config/assets/41551785/93350f05-7a1c-4f19-adac-f3e912ec6641)

### Kakariko

![kakariko](https://github.com/Yeshey/nixOS-Config/assets/41551785/87c28630-9c44-4931-a4d2-573376999ff6)

&nbsp;

&nbsp;

&nbsp;

[story.md 🥀](https://github.com/Yeshey/nixOS-Config/blob/main/story.md)
