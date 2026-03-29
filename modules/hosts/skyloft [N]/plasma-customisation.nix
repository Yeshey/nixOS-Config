{
  flake.modules.homeManager.skyloft = 
    { lib, osConfig, ... }: 
    let
      isKdePlasma = osConfig.services.desktopManager.plasma6.enable or false;
    in
    {
      config = lib.mkIf isKdePlasma {
        # server should auto logout bc GUI uses a lot of CPU
        xdg.configFile."powerdevilrc".text = ''
          [AC][RunScript]
          IdleTimeoutCommand=qdbus org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout
        '';
      };
    };
}