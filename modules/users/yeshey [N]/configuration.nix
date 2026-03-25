{ inputs, ... }:

let
  username = "yeshey";
in
{
  flake.modules.nixos."${username}" =
    { pkgs, ... }:
    {
      home-manager.users."${username}" = {
        imports = [
          inputs.self.modules.homeManager."${username}"
        ];
      };

      users.users."${username}" = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "docker"
          "kvm"
          "libvirtd"
          "adbusers"
        ];
        # generated with mkpasswd --method=sha-512 --rounds=2000000
        hashedPassword = "$6$rounds=2000000$/pvZKZOnJE51jPnR$FDiOHyOvkouz36fW8MLiPYOFdEYf/SknZWVc9tqV039bOEvQMfH9TsezvITcbsMwqVHFzA0uEPwS0msabEUKg1";
        openssh.authorizedKeys.keyFiles = [ ../../../id_ed_mykey.pub ];
        shell = pkgs.zsh;
      };
      users.users.root.openssh.authorizedKeys.keyFiles = [ ../../../id_ed_mykey.pub ];

      programs.zsh.enable = true;
    };
}