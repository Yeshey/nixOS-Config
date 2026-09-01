{
  inputs,
  ...
}:
{
  flake.modules.homeManager.onikao =
    { pkgs, ... }:

    let
      # A wrapper script to run xautolock with the desired options
      # This avoids quoting issues in the .desktop file
      xautolockWrapper = pkgs.writeShellScript "xautolock-wrapper" ''
        # 1 minute idle timeout (change to 10 later)
        ${pkgs.xautolock}/bin/xautolock -time 10 \
          -locker "${pkgs.kdePackages.qttools}/bin/qdbus org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout" \
          -detectsleep
      '';
    in {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];

      #config = lib.mkIf (osConfig.systemConstants.isKdePlasma or false) {
      config = {
        # 1. Ensure xautolock is installed
        home.packages = [ pkgs.xautolock ];

        # 2. Create an autostart .desktop file
        xdg.configFile."autostart/xautolock.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Idle Logout (xautolock)
          Exec=${xautolockWrapper}
          X-KDE-autostart-condition=ksmserver
          X-GNOME-Autostart-enabled=true
          StartupNotify=false
        '';

        # 3. Remove the old PowerDevil config – it's not needed
        # programs.plasma.configFile."powerdevilrc"."AC/RunScript" ... (delete this)
      };
    };
}