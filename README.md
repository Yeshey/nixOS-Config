# nix & nixOS Configuration / Linux Config
The spiciest config on the market [😳🥵💦](https://matias.me/nsfw/)

My reproducible nix Configuration & other configuration files.
More Documentation (for myself) about NixOS in my [TechNotes Repo](https://github.com/Yeshey/TechNotes).

It has my personal configuration for my Lenovo Legion laptop(`hyrulecastle`), my MS Surface Pro 7(`kakariko`), my phones `nix-on-droid` and my Oracle `aarch64` server(`skyloft`).

**debugging** Use nix-tree to see what packages your current system depends on: `nix run nixpkgs#nix-tree -- /run/current-system`. Then use `/` to search for packages you want.

## Installing on a new computer

- `sudo nixos-rebuild --flake github:Yeshey/nixOS-Config#hyrulecastle boot --max-jobs 2 --cores 4 --option experimental-features "nix-command flakes pipe-operators" --impure`

- You might need to create the home manager folder manually `mkdir ~/.local/state/nix/profiles`

- You'll have to find the syncthing ID by going to http://127.0.0.1:8384, getting the ID, and adding it in the syncthing config

- You'll have to add the new machine public key to the secrets for agenix with `cat /etc/ssh/ssh_host_rsa_key.pub` and add it in the `secrets/secrets.nix` and rekey the keys `cd ~/.setup/secrets` and `agenix --rekey`.

- Right click on wastebin and configure to delete trash after 7 days, still don't know how to declare this.

- For remote backups, I'm using OneDrive with rclone, you will have to add the rclone remote with `rclone config` either as yeshey (for hyrulecastle) or as root (for skyloft) and set the name of the remote to `OneDriveISCTE`.

- You'll need to run `sudo wg show wgOracle` to see the public keys and update the `publicKey` in `wireguardServer.nix` and `wireguardClient.nix`

- If you get rate limited, you can use authenticated requests:
  - `gh auth login`
  - `sudo nixos-rebuild --flake ~/.setup#hyrulecastle --option cores 6 --option max-jobs 3 switch --option access-tokens "github.com=$(gh auth token)"`

<details>
<summary><strong>Nix-on-Droid</strong></summary>

(don't forget you can connect your phone to the PC and control it with something like `scrcpy --render-driver=opengl`). Install nix-on-droid with flakes support, (you can add channels to have access to nix-shell by installing [the normal packages](https://nix-on-droid.unboiled.info/upgrade.txt)). My flake has inputs that need the pipe operator, because 24.05 didn't have support for that we need to update nix first:
- `vi ~/.config/nix-on-droid/flake.nix` and update only nixpkgs to the latest version
- Rebuild: `nix-on-droid switch --flake ~/.config/nix-on-droid#default`
- Then build with my flake: `nix shell nixpkgs#git nixpkgs#nix-output-monitor -c bash -c "nix-on-droid switch --flake github:Yeshey/nixOS-Config#nix-on-droid --max-jobs 2 --option 'experimental-features' 'nix-command flakes pipe-operators' -v |& nom"`
- You'll have to find a way to send the ssh keys, `scp` isn't working, you can do this:
  - Transfer the files to `Downloads` folder in the phone and then use [this](https://github.com/nix-community/nix-on-droid/issues/238#issuecomment-1826796452) method to get it in nix-on-droid
- If you want to add a [termux:widget](https://github.com/termux/termux-widget) to connect to your computers with their reverse proxy to the server (can be enabled with [autosshReverseProxy](https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/autosshReverseProxy.nix)) you can add to `~/.shortcuts/` these files:
  - `connectHyruleCastle`:
    ```sh
    ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@143.47.53.175 "ssh -t -p 2232 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@localhost"
    ```
  - `connectKakariko`:
    ```sh
    ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@143.47.53.175 "ssh -t -p 2333 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@localhost"
    ```
  - `connectSkyloft`:
    ```sh
    ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null yeshey@143.47.53.175
    ```
</details>

<details>
<summary><strong>Non-NixOS Home-manager standalone with flakes (not tested rn)</strong></summary>

1. Install nix, follow [hm standalone](https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone). (These instructions assume system wide installation)
2. `mkdir ~/.setup ; git clone git@github.com:Yeshey/nixOS-Config.git ~/.setup/ --depth 1`
3. Follow [flakes Standalone setup](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone), and use `nix run home-manager/master -- init --switch /home/yeshey/.setup` to set up the hm in the right place.
4. `home-manager switch --flake ~/.setup#yeshey` to activate the configuration
5. Set zsh shell as default:
   `echo "/home/$USER/.nix-profile/bin/zsh" | sudo tee -a /etc/shells`
   `chsh -s "/home/$USER/.nix-profile/bin/zsh" "$USER"`

</details>

## Credits

- Initially introduced to nix and nixOS by [Kylix](https://github.com/kylixafonso) 👀
- First iteration inspired by [Matthias Benaets'](https://github.com/MatthiasBenaets) [configuration](https://github.com/MatthiasBenaets/nixos-config) and his [video](https://www.youtube.com/watch?v=AGVXJ-TIv3Y);
- Derived from [LongerHV's](https://github.com/LongerHV) [nixos-configuration](https://github.com/LongerHV/nixos-configuration/tree/master);
- Based on [Misterio77's](https://github.com/Misterio77) [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs);
- Inspiered by [pinage404](https://gitlab.com/pinage404) [dotfiles](https://gitlab.com/pinage404/dotfiles)
- Refactored using the [Dendritic Pattern](https://github.com/mightyiam/dendritic), basing off of [these docs and examples](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)!
- (Future/To-Do?) Maybe It would have been easier to use the [`den` framework](https://github.com/vic/den)… keep an eye on it.

## Highlights:

- **Structure**
    - Using the dendritic pattern as per [these docs](https://github.com/Doc-Steve/dendritic-design-with-flake-parts). 
    - Additionally, I've added a `mkNixOnDroid` function.
    - NixOS Modules generally call HomeManager themselves, so I don't have to call it in the user as well. This way if I define `gnome-full` module on a host, the users with Home-Manager will automatically receive the HomeManager `gnome-full` module as well.
    - Tiered modules. For example [system types](https://github.com/Yeshey/nixOS-Config/tree/main/modules/system/system%20types), [gnome](https://github.com/Yeshey/nixOS-Config/tree/main/modules/system/settings/desktop-managers/gnome), [kdePlasma](https://github.com/Yeshey/nixOS-Config/tree/main/modules/system/settings/desktop-managers/kdePlasma). The called module is `system-desktop` which is the "leaf" module that calls the `system-desktop-tier` HM and the NixOS modules. We do this separation to allow the NixOS module to call the HomeManager ones without importing the same module several times, as that causes problems especially with `impermanence`.
    - If a User wants to add more configuration to their `gnome` desktop or example, they can use the Constants aspect to check if the desktop was enabled, as the module sets `systemConstants.isGnome = true;`. [Example](https://github.com/Yeshey/nixOS-Config/blob/main/modules/users/yeshey%20%5BN%5D/gnome-customisation.nix)
    - Unstable packages available at `pkgs.unstable.<package>`, [NUR](https://github.com/nix-community/NUR) packages available at `pkgs.nur.<package>` using overlays as defined [here](https://github.com/Yeshey/nixOS-Config/blob/main/modules/system/system%20types/1%20-%20system-minimal%20%5BNDnd%5D/nixos/nixos-minimal-tier.nix) for NixOS and [here](https://github.com/Yeshey/nixOS-Config/tree/main/modules/system/settings/standalone-hm%20%5Bn%5D) for Home Manager standalone.

- **Auto Updates On Shutdown** - I have a GitHub action that updates my flake.lock every 2 weeks [update-flake.yml](https://github.com/Yeshey/nixOS-Config/blob/main/.github/workflows/update-flake.yml). Then I have a service that updates the PC while shutting down, while keeping services like `sshd`, `oomd`, etc. working: [upgrade-on-shutdown.nix](https://github.com/Yeshey/nixOS-Config/tree/main/modules/system/settings/upgrade-on-shutdown%20%5BN%5D);

- **Syncthing** - Declaratively set syncthing with HM, including ignore patterns: [syncthing [N]](https://github.com/Yeshey/nixOS-Config/tree/main/modules/services/syncthing%20%5BN%5D)

- ~~**LUKS on LVM with LVM cache**~~ **bcacheFS as root ( ͡° ͜ʖ ͡°)** - across microSD (background_target) and NVME (foreground_target and promote_target) on `kakariko`: [hardware.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/hosts/kakariko%20%5BN%5D/hardware.nix);

- **On-Demand Onedrive with rclone mount** - A very resilient systemd service that mounts my Onedrive storage. [onedrive](https://github.com/abraunegg/onedrive) doesn't work without my university explicitly allowing the application, but rclone is pre-authorized by microsoft. [rclone-mount-onedrive.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/services/rclone-mount-onedrive%20%5BNn%5D/rclone-mount-onedrive.nix)

- **clean** - `clean` is an alias for a script that cleans user and system dangling nix packages, optimises the store, uninstalls unused Flatpak packages, and removes dangling docker and podman images, volumes and networks: [`my-scripts.nix`]([https://github.com/Yeshey/nixOS-Config/blob/main/modules/home-manager/myHome/myScripts.nix) and for [`mySystem`](https://github.com/Yeshey/nixOS-Config/blob/main/modules/nixos/mySystem/myScripts.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/misc/my-scritps%20%5BNn%5D/my-scripts.nix))

- **pci-passthrough (not refactored back yet)** - for passing my `NVIDIA GeForce RTX 2060 Mobile` to a virt-manager VM and using my intel processor for the host: [pci-passthrough.nix](https://github.com/Yeshey/nixOS-Config/blob/main/nixos/hyrulecastle/pci-passthrough.nix), but better yet:

- **VGPU (not refactored back yet)** - Unlocked VGPU functionality on my consumer nvidia card: [vgpu.nix](https://github.com/Yeshey/nixOS-Config/blob/main/nixos/hyrulecastle/vgpu.nix). Using my module, more details there: [nixos-nvidia-vgpu](https://github.com/Yeshey/nixos-nvidia-vgpu);

- **Ollama with open-webui and searx** - Ollama and Open-WebUI can be activated with a single module: [ollama [N]](https://github.com/Yeshey/nixOS-Config/tree/main/modules/services/hosting/ollama%20%5BN%5D). If searx, to use your own search engine, is also activated, models on openweb-ui are able to search the internet through it: [searx [N]](https://github.com/Yeshey/nixOS-Config/tree/main/modules/services/hosting/searx%20%5BN%5D)

- **i2p firefox profile** - Home manager auto creates a firefox profile able to access the hidden i2p net when the `i2p` module is imported, and makes a `.desktop` file for easy access: [i2p.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/services/i2p%20%5BN%5D/i2p.nix)

- **Safe-rm** - I nuked my PC once by running `sudo rm -r /*` instead of `sudo -r rm ./*`, so I decided to change all my `rm` calls to `safe-rm` calls through changing the binary and adding aliases, both in Home Manager and NixOS: [safe-rm.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/system/settings/safe-rm%20%5BN%5D/safe-rm.nix)

- **VSCodium and Zed Editor** - Both configured extensible for the best developer experience. Notabily, they both use `ltex` with n-gram support for good grammar correction (in Portuguese): [vscodium [nd]](https://github.com/Yeshey/nixOS-Config/tree/main/modules/programs/vscodium%20%5Bnd%5D), [zed-editor [n]](https://github.com/Yeshey/nixOS-Config/tree/main/modules/programs/zed-editor%20%5Bn%5D)

- **Nix-on-Droid with Root!** - Using my own nix-on-droid fork with a couple changes so I can activate root on my nix-on-droid installation: [root-droid.nix](https://github.com/Yeshey/nixOS-Config/blob/main/modules/hosts/nix-on-droid%20%5BN%5D/root-droid.nix)

## Gallery

### HyruleCastle

![hyrulecastle](https://github.com/Yeshey/nixOS-Config/assets/41551785/93350f05-7a1c-4f19-adac-f3e912ec6641)

### Kakariko

![kakariko](https://github.com/Yeshey/nixOS-Config/assets/41551785/87c28630-9c44-4931-a4d2-573376999ff6)

&nbsp;

&nbsp;

&nbsp;

[story.md 🥀](https://github.com/Yeshey/nixOS-Config/blob/main/story.md)
