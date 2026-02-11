{
    inputs = {
        nixpkgs.follows = "nixpkgs";
    };

    outputs = {...}: {
        homeManagerModules.default = {
            wayland.windowManager.hyprland = {
                enable = true;
                package = null;
                portalPackage = null;

                settings = {
                    "$mod" = "SUPER";

                    bind = [
                        "$mod, T, exec, alacritty"
                    ];
                };
            };

            # Graphical terminal emulator.
            programs.alacritty = {
                enable = true;
                settings = {
                    terminal.shell.program = "fish";
                    window.opacity = 0.9;
                    font = {
                        size = 12;
                        normal.family = "OverpassM Nerd Font";
                    };
                };
            };
        };
    };
}
