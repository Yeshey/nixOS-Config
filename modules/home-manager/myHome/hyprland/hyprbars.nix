{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;

  hyprbars =
    (pkgs.inputs.hyprland-plugins.hyprbars.override {
      # Make sure it's using the same hyprland package as we are
      hyprland = config.wayland.windowManager.hyprland.package;
    })
    .overrideAttrs
    (old: {
      # Yeet the initialization notification (I hate it)
      postPatch =
        (old.postPatch or "")
        + ''
          ${lib.getExe pkgs.gnused} -i '/Initialized successfully/d' main.cpp
        '';
    });
in
{

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      plugins = [ inputs.hyprland-plugins.packages."${pkgs.system}".hyprbars ];
      
      settings = {
        "plugin:hyprbars" = {
          bar_height = 25;
          bar_color = "0xdd${lib.removePrefix "#" c.base00}";
          "col.text" = "0xee${lib.removePrefix "#" c.base01}";
          
          # bar_text_font = config.fontProfiles.regular.family;
          bar_text_size = 12;
          bar_part_of_window = true;
          hyprbars-button = let
            closeAction = "hyprctl dispatch killactive";

            isOnSpecial = ''hyprctl activewindow -j | jq -re 'select(.workspace.name == "special")' >/dev/null'';
            moveToSpecial = "hyprctl dispatch movetoworkspacesilent special";
            moveToActive = "hyprctl dispatch movetoworkspacesilent name:$(hyprctl -j activeworkspace | jq -re '.name')";
            minimizeAction = "${isOnSpecial} && ${moveToActive} || ${moveToSpecial}";

            maximizeAction = "hyprctl dispatch togglefloating";
          in [
            # Red close button
            "rgb(${lib.removePrefix "#" c.base02}),12,,${closeAction}" # config.colorscheme.harmonized.red
            # Yellow "minimize" (send to special workspace) button
            "rgb(${lib.removePrefix "#" c.base03}),12,,${minimizeAction}" # config.colorscheme.harmonized.yellow
            # Green "maximize" (togglefloating) button
            "rgb(${lib.removePrefix "#" c.base04}),12,,${maximizeAction}" # config.colorscheme.harmonized.green
          ];
        };
        bind = let
          barsEnabled = "hyprctl -j getoption plugin:hyprbars:bar_height | ${lib.getExe pkgs.jq} -re '.int != 0'";
          setBarHeight = height: "hyprctl keyword plugin:hyprbars:bar_height ${toString height}";
          toggleOn = setBarHeight config.wayland.windowManager.hyprland.settings."plugin:hyprbars".bar_height;
          toggleOff = setBarHeight 0;
        in ["SUPER,m,exec,${barsEnabled} && ${toggleOff} || ${toggleOn}"];
      };
      
    };
  };
}
