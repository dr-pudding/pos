{
    pkgs,
    lib,
    fuzzelRun,
    ...
}: {
    wayland.windowManager.hyprland = {
        enable = true;
        package = null;
        portalPackage = null;
        settings = {
            "$mod" = "SUPER";

            exec-once = [
                "waybar"
            ];

            bind = [
                # Quick-launch applications.
                "$mod, T, exec, alacritty" # Terminal emulator shortcut.
                "$mod, B, exec, qutebrowser" # Browser shortcut.

                # Quick-launch utilities.
                "$$mod, Z, exec, ${lib.getExe fuzzelRun}" # Application launcher shortcut.
                ", Print, exec, hyprshot --mode region --output-folder $HOME/stuff/screenshots" # Screenshot shortcut.

                # Manage windows.
                "$mod, W, killactive"
                "$mod, X, togglesplit"
                "$mod, C, pseudo"
                "$mod, V, togglefloating"

                # Select active window.
                "$mod, left, movefocus, l"
                "$mod, right, movefocus, r"
                "$mod, up, movefocus, u"
                "$mod, down, movefocus, d"

                # Move active window.
                "$mod SHIFT, left, movewindow, l"
                "$mod SHIFT, right, movewindow, r"
                "$mod SHIFT, up, movewindow, u"
                "$mod SHIFT, down, movewindow, d"

                # Resize active window.
                "$mod ALT, left, resizeactive, -64 0"
                "$mod ALT, right, resizeactive, 64 0"
                "$mod ALT, up, resizeactive, 0 -64"
                "$mod ALT, down, resizeactive, 0 64"

                # Swap workspaces.
                "$mod, 1, workspace, 1"
                "$mod, 2, workspace, 2"
                "$mod, 3, workspace, 3"
                "$mod, 4, workspace, 4"
                "$mod, 5, workspace, 5"
                "$mod, 6, workspace, 6"
                "$mod, 7, workspace, 7"
                "$mod, 8, workspace, 8"
                "$mod, 9, workspace, 9"
                "$mod, 0, workspace, 10"

                # Move windows between workspaces.
                "$mod SHIFT, 1, movetoworkspace, 1"
                "$mod SHIFT, 2, movetoworkspace, 2"
                "$mod SHIFT, 3, movetoworkspace, 3"
                "$mod SHIFT, 4, movetoworkspace, 4"
                "$mod SHIFT, 5, movetoworkspace, 5"
                "$mod SHIFT, 6, movetoworkspace, 6"
                "$mod SHIFT, 7, movetoworkspace, 7"
                "$mod SHIFT, 8, movetoworkspace, 8"
                "$mod SHIFT, 9, movetoworkspace, 9"
                "$mod SHIFT, 0, movetoworkspace, 10"
            ];

            bindm = [
                # Move/resize windows using the mouse.
                "$mod, mouse:272, movewindow"
                "$mod, mouse:273, resizewindow"
            ];

            bindle = [
                ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"
                ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"
                ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
                ", XF86AudioPlay, exec, playerctl play-pause"
                ", XF86AudioNext, exec, playerctl next"
                ", XF86AudioPrev, exec, playerctl previous"
                ", XF86MonBrightnessUp, exec, brightnessctl set 10%+"
                ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
            ];

            general = {
                layout = "dwindle";

                # Style the window borders.
                gaps_in = 2;
                gaps_out = 2;
                border_size = 2;
                "col.active_border" = "rgba($mauveAlphaee) rgba($lavenderAlphaee) 45deg";
                "col.inactive_border" = "rgba($surface0Alphaee)";
            };

            # Define the primary tiling behaviour
            dwindle = {
                pseudotile = "yes";
                preserve_split = "yes";
                split_width_multiplier = 1.25;
            };

            # Additional window styling.
            decoration = {
                rounding = 3;
                blur.enabled = false;
            };
        };
    };

    # Use custom desktop wallpaper.
    services.hyprpaper = {
        enable = true;
        settings = {
            preload = ["~/stuff/wallpaper.png"];
            wallpaper = [",~/stuff/wallpaper.png"];
        };
    };

    home.packages = with pkgs; [
        hyprshot # Screenshot utility
    ];
}
