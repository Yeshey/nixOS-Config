{
  flake.modules.homeManager.skyloft =
    { lib, osConfig, ... }:
    {
      config = lib.mkIf (osConfig.systemConstants.isKdePlasma or false) {
        # server should auto logout bc GUI uses a lot of CPU
        xdg.configFile."powerdevilrc".text = ''
          [AC][RunScript]
          IdleTimeoutCommand=qdbus org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout
        '';
      };
    };
}