# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
# Generated with: nix-shell -p dconf2nix --command "dconf dump / | dconf2nix -e --verbose > dconf.nix"

# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}@args:

let
  cfg = config.myHome.gnome;
in
with lib.hm.gvariant;
{
  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    dconf.settings = {
      "org/gnome/Characters" = {
        recent-characters = [
          "🚌"
          "👍"
          "🥲"
          "🥰"
          "😆"
          "😁"
          "😊"
          "🤣"
        ];
      };

      "org/gnome/Totem" = {
        active-plugins = [
          "vimeo"
          "screenshot"
          "autoload-subtitles"
          "mpris"
          "rotation"
          "recent"
          "variable-rate"
          "skipto"
          "save-file"
          "screensaver"
          "open-directory"
          "apple-trailers"
          "movie-properties"
        ];
        subtitle-encoding = "UTF-8";
      };

      "org/gnome/baobab/ui" = {
        is-maximized = false;
        window-size = mkTuple [
          960
          600
        ];
      };

      "org/gnome/cheese" = {
        burst-delay = 1000;
      };

      "org/gnome/clocks" = {
        timers = "[{'duration': <240>, 'name': <''>}]";
      };

      "org/gnome/clocks/state/window" = {
        maximized = false;
        panel-id = "world";
        size = mkTuple [
          870
          690
        ];
      };

      "org/gnome/control-center" = {
        last-panel = "power";
        window-state = mkTuple [
          980
          640
        ];
      };

      "org/gnome/desktop/app-folders" = {
        folder-children = [
          "Utilities"
          "YaST"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Utilities" = {
        apps = [
          "gnome-abrt.desktop"
          "gnome-system-log.desktop"
          "nm-connection-editor.desktop"
          "org.gnome.baobab.desktop"
          "org.gnome.Connections.desktop"
          "org.gnome.DejaDup.desktop"
          "org.gnome.Dictionary.desktop"
          "org.gnome.DiskUtility.desktop"
          "org.gnome.eog.desktop"
          "org.gnome.Evince.desktop"
          "org.gnome.FileRoller.desktop"
          "org.gnome.fonts.desktop"
          "org.gnome.seahorse.Application.desktop"
          "org.gnome.tweaks.desktop"
          "org.gnome.Usage.desktop"
          "vinagre.desktop"
        ];
        categories = [ "X-GNOME-Utilities" ];
        name = "X-GNOME-Utilities.directory";
        translate = true;
      };

      "org/gnome/desktop/app-folders/folders/YaST" = {
        categories = [ "X-SuSE-YaST" ];
        name = "suse-yast.directory";
        translate = true;
      };

      "org/gnome/desktop/calendar" = {
        show-weekdate = false;
      };

      "org/gnome/desktop/input-sources" = {
        show-all-sources = false;
        sources = [
          (mkTuple [
            "xkb"
            "pt"
          ])
        ];
        xkb-options = [ "terminate:ctrl_alt_bksp" ];
      };

      "org/gnome/desktop/interface" = {
        clock-show-seconds = true;
        clock-show-weekday = true;
        color-scheme = "prefer-dark";
        font-antialiasing = "grayscale";
        font-hinting = "slight";
        show-battery-percentage = true;
      };

      "org/gnome/desktop/notifications" = {
        application-children = [
          "org-gnome-nautilus"
          "org-gnome-console"
          "firefox"
          "com-google-androidstudio"
          "vivaldi-stable"
          "discord"
          "gnome-power-panel"
          "code"
          "org-gnome-epiphany"
          "github-desktop"
          "org-gnome-baobab"
          "steam"
        ];
      };

      "org/gnome/desktop/notifications/application/clion" = {
        application-id = "clion.desktop";
      };

      "org/gnome/desktop/notifications/application/code" = {
        application-id = "code.desktop";
      };

      "org/gnome/desktop/notifications/application/codium" = {
        application-id = "codium.desktop";
      };

      "org/gnome/desktop/notifications/application/com-google-androidstudio" = {
        application-id = "com.google.AndroidStudio.desktop";
      };

      "org/gnome/desktop/notifications/application/discord" = {
        application-id = "discord.desktop";
      };

      "org/gnome/desktop/notifications/application/firefox" = {
        application-id = "firefox.desktop";
      };

      "org/gnome/desktop/notifications/application/github-desktop" = {
        application-id = "github-desktop.desktop";
      };

      "org/gnome/desktop/notifications/application/gnome-network-panel" = {
        application-id = "gnome-network-panel.desktop";
      };

      "org/gnome/desktop/notifications/application/gnome-power-panel" = {
        application-id = "gnome-power-panel.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-baobab" = {
        application-id = "org.gnome.baobab.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-clocks" = {
        application-id = "org.gnome.clocks.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-console" = {
        application-id = "org.gnome.Console.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-epiphany" = {
        application-id = "org.gnome.Epiphany.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-extensions-desktop" = {
        application-id = "org.gnome.Extensions.desktop.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-fileroller" = {
        application-id = "org.gnome.FileRoller.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-nautilus" = {
        application-id = "org.gnome.Nautilus.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-settings" = {
        application-id = "org.gnome.Settings.desktop";
      };

      "org/gnome/desktop/notifications/application/org-gnome-tweaks" = {
        application-id = "org.gnome.tweaks.desktop";
      };

      "org/gnome/desktop/notifications/application/p3x-onenote" = {
        application-id = "p3x-onenote.desktop";
      };

      "org/gnome/desktop/notifications/application/steam" = {
        application-id = "steam.desktop";
      };

      "org/gnome/desktop/notifications/application/vivaldi-stable" = {
        application-id = "vivaldi-stable.desktop";
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        click-method = "areas";
        tap-to-click = true;
      };

      "org/gnome/desktop/privacy" = {
        old-files-age = mkUint32 30;
        recent-files-max-age = -1;
        remove-old-temp-files = true;
        remove-old-trash-files = true;
      };

      "org/gnome/desktop/screensaver" = {
        lock-delay = mkUint32 30;
        lock-enabled = true;
      };

      "org/gnome/desktop/session" = {
        idle-delay = mkUint32 0;
      };

      "org/gnome/desktop/sound" = {
        allow-volume-above-100-percent = true;
        event-sounds = true;
        theme-name = "__custom";
      };

      "org/gnome/desktop/wm/keybindings" = {
        show-desktop = [ "<Super>d" ];
        switch-applications = [ ];
        switch-applications-backward = [ ];
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
        resize-with-right-button = true;
      };

      "org/gnome/eog/view" = {
        background-color = "rgb(0,0,0)";
        use-background-color = true;
      };

      "org/gnome/epiphany" = {
        ask-for-default = false;
      };

      "org/gnome/epiphany/state" = {
        is-maximized = false;
        window-position = mkTuple [
          (-1)
          (-1)
        ];
        window-size = mkTuple [
          1024
          768
        ];
      };

      "org/gnome/evince/default" = {
        window-ratio = mkTuple [
          1.007889
          0.712682
        ];
      };

      "org/gnome/evolution-data-server" = {
        migrated = true;
        network-monitor-gio-name = "";
      };

      "org/gnome/file-roller/dialogs/extract" = {
        recreate-folders = true;
        skip-newer = false;
      };

      "org/gnome/file-roller/listing" = {
        list-mode = "as-folder";
        name-column-width = 250;
        show-path = false;
        sort-method = "name";
        sort-type = "ascending";
      };

      "org/gnome/file-roller/ui" = {
        sidebar-width = 200;
        window-height = 480;
        window-width = 600;
      };

      "org/gnome/gnome-system-monitor" = {
        current-tab = "resources";
        maximized = false;
        network-total-in-bits = false;
        show-dependencies = false;
        show-whose-processes = "user";
        window-state = mkTuple [
          700
          500
        ];
      };

      "org/gnome/gnome-system-monitor/disktreenew" = {
        col-1-visible = true;
        col-1-width = 178;
        col-6-visible = true;
        col-6-width = 0;
      };

      "org/gnome/gnome-system-monitor/proctree" = {
        columns-order = [
          0
          1
          2
          3
          4
          6
          8
          9
          10
          11
          12
          13
          14
          15
          16
          17
          18
          19
          20
          21
          22
          23
          24
          25
          26
        ];
        sort-col = 8;
        sort-order = 0;
      };

      "org/gnome/mutter" = {
        attach-modal-dialogs = true;
        dynamic-workspaces = true;
        edge-tiling = true;
        focus-change-on-pointer-rest = true;
        workspaces-only-on-primary = true;
      };

      "org/gnome/nautilus/compression" = {
        default-compression-format = "tar.xz";
      };

      "org/gnome/nautilus/preferences" = {
        click-policy = "single";
        default-folder-viewer = "icon-view";
        migrated-gtk-settings = true;
        search-filter-time-type = "last_modified";
        search-view = "list-view";
        show-create-link = true;
        show-delete-permanently = true;
      };

      "org/gnome/nautilus/window-state" = {
        initial-size = mkTuple [
          890
          550
        ];
        maximized = false;
      };

      "org/gnome/nm-applet/eap/022163dc-8595-4c8a-ad7b-ea70157bcc82" = {
        ignore-ca-cert = true;
        ignore-phase2-ca-cert = false;
      };

      "org/gnome/nm-applet/eap/5cc7fad6-0fa4-4474-9a16-b21cef0dee33" = {
        ignore-ca-cert = true;
        ignore-phase2-ca-cert = false;
      };

      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Control><Alt>m";
        command = "vlc ${config.myHome.dataStoragePath}/PersonalFiles/Timeless/Music/AllMusic-mp3";
        name = "AllMusic";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Control><Alt>e";
        command = "vlc \"${config.myHome.dataStoragePath}/PersonalFiles/Timeless/Music/Playlists for mp3/Músicas de Estudo.m3u8\"";
        name = "StudyMusic";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Control><Alt>t";
        command = "kgx";
        name = "Launch New Terminal";
      };

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-timeout = 1500;
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-timeout = 900;
        sleep-inactive-battery-type = "suspend";
      };

      "org/gnome/shell" = {
        app-picker-layout = "[{'org.gnome.Geary.desktop': <{'position': <0>}>, 'org.gnome.Contacts.desktop': <{'position': <1>}>, 'org.gnome.Weather.desktop': <{'position': <2>}>, 'org.gnome.clocks.desktop': <{'position': <3>}>, 'org.gnome.Maps.desktop': <{'position': <4>}>, 'org.gnome.Photos.desktop': <{'position': <5>}>, 'org.gnome.Totem.desktop': <{'position': <6>}>, 'org.gnome.Calculator.desktop': <{'position': <7>}>, 'simple-scan.desktop': <{'position': <8>}>, 'org.gnome.Settings.desktop': <{'position': <9>}>, 'gnome-system-monitor.desktop': <{'position': <10>}>, 'yelp.desktop': <{'position': <11>}>, 'Utilities': <{'position': <12>}>, 'org.gnome.Cheese.desktop': <{'position': <13>}>, 'AnyDesk.desktop': <{'position': <14>}>, 'btop.desktop': <{'position': <15>}>, 'org.gnome.Calendar.desktop': <{'position': <16>}>, 'discord.desktop': <{'position': <17>}>, 'org.gnome.Extensions.desktop': <{'position': <18>}>, 'firefox.desktop': <{'position': <19>}>, 'github-desktop.desktop': <{'position': <20>}>, 'gparted.desktop': <{'position': <21>}>, 'org.pipewire.Helvum.desktop': <{'position': <22>}>, 'htop.desktop': <{'position': <23>}>}, {'startcenter.desktop': <{'position': <0>}>, 'base.desktop': <{'position': <1>}>, 'calc.desktop': <{'position': <2>}>, 'draw.desktop': <{'position': <3>}>, 'impress.desktop': <{'position': <4>}>, 'math.desktop': <{'position': <5>}>, 'writer.desktop': <{'position': <6>}>, 'cups.desktop': <{'position': <7>}>, 'org.gnome.Music.desktop': <{'position': <8>}>, 'nixos-manual.desktop': <{'position': <9>}>, 'com.obsproject.Studio.desktop': <{'position': <10>}>, 'p3x-onenote.desktop': <{'position': <11>}>, 'com.github.jeromerobert.pdfarranger.desktop': <{'position': <12>}>, 'psensor.desktop': <{'position': <13>}>, 'org.qbittorrent.qBittorrent.desktop': <{'position': <14>}>, 'org.gnome.Software.desktop': <{'position': <15>}>, 'smartcode-stremio.desktop': <{'position': <16>}>, 'org.gnome.TextEditor.desktop': <{'position': <17>}>, 'org.gnome.Tour.desktop': <{'position': <18>}>, 'code.desktop': <{'position': <19>}>, 'vlc.desktop': <{'position': <20>}>, 'xterm.desktop': <{'position': <21>}>}]";
        disable-user-extensions = false;
        disabled-extensions = [
          # "rounded-window-corners@yilozt"
          # "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        ];
        enabled-extensions = [
          "clipboard-history@alexsaveau.dev"
          "burn-my-windows@schneegans.github.com"
          "clipboard-indicator@tudmotu.com"
          "hibernate-status@dromi"
          "trayIconsReloaded@selfmade.pl"
        ];
        # favorite-apps = [ "org.gnome.Nautilus.desktop" "org.gnome.Console.desktop" "floorp.desktop" ];
        last-selected-power-profile = "power-saver";
        welcome-dialog-last-shown-version = "42.4";
      };

      "org/gnome/shell/app-switcher" = {
        current-workspace-only = false;
      };

      /*
      # you are better off doing it manually
      active-profile = "/home/yeshey/.config/burn-my-windows/profiles/1716743297152538.conf"; # with
      [burn-my-windows-profile]
      fire-enable-effect=false
      hexagon-enable-effect=true
      hexagon-animation-time=550
      */
      "org/gnome/shell/extensions/burn-my-windows" = {
        close-preview-effect = "";
        fire-close-effect = false;
        glide-close-effect = false;
        glitch-close-effect = true;
        glitch-open-effect = true;
        hexagon-animation-time = 600;
        hexagon-close-effect = false;
        hexagon-open-effect = true;
        incinerate-animation-time = 1000;
        incinerate-close-effect = false;
        open-preview-effect = "";
        tv-close-effect = true;
        tv-open-effect = false;
        wisps-open-effect = false;
      };

      "org/gnome/shell/extensions/clipboard-indicator" = {
        disable-down-arrow = true;
        history-size = 200;
      };

      "org/gnome/shell/extensions/rounded-window-corners" = {
        custom-rounded-corner-settings = "@a{sv} {}";
        global-rounded-corner-settings = "{'padding': <{'left': <uint32 1>, 'right': <uint32 1>, 'top': <uint32 1>, 'bottom': <uint32 1>}>, 'keep_rounded_corners': <{'maximized': <false>, 'fullscreen': <false>}>, 'border_radius': <uint32 12>, 'smoothing': <uint32 0>}";
        settings-version = mkUint32 5;
      };

      "org/gnome/shell/extensions/trayIconsReloaded" = {
        icon-size = 20;
        icons-limit = 4;
        tray-margin-left = 4;
      };

      "org/gnome/shell/window-switcher" = {
        current-workspace-only = false;
      };

      "org/gnome/shell/world-clocks" = {
        locations = "@av []";
      };

      "org/gnome/software" = {
        check-timestamp = mkInt64 1675544601;
        first-run = false;
      };

      "org/gnome/tweaks" = {
        show-extensions-notice = false;
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        date-format = "regular";
        location-mode = "path-bar";
        show-hidden = false;
        show-size-column = true;
        show-type-column = true;
        sidebar-width = 169;
        sort-column = "name";
        sort-directories-first = false;
        sort-order = "ascending";
        type-format = "category";
        window-size = mkTuple [
          896
          682
        ];
      };

      "org/gtk/settings/color-chooser" = {
        custom-colors = [
          (mkTuple [
            0.988235
            0.686275
          ])
        ];
        selected-color = mkTuple [
          true
          0.988235
        ];
      };

      "org/gtk/settings/file-chooser" = {
        date-format = "regular";
        location-mode = "path-bar";
        show-hidden = false;
        show-size-column = true;
        show-type-column = true;
        sidebar-width = 157;
        sort-column = "name";
        sort-directories-first = false;
        sort-order = "ascending";
        type-format = "category";
        window-position = mkTuple [
          165
          32
        ];
        window-size = mkTuple [
          1203
          833
        ];
      };

      "system/proxy" = {
        mode = "none";
      };
    };
  };
}
