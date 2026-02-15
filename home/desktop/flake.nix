{
    inputs = {
        unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixpkgs.follows = "nixpkgs";
    };

    outputs = {...}: {
        homeManagerModules.default = {
            lib,
            config,
            ...
        }: {
            imports = [
                ./hyprland.nix # Desktop window manager.
                ./waybar.nix # Status bar at the top of the screen.
                ./qb.nix # Vim-like web browser.
            ];

            # Copy over the default wallpaper if one has not been assigned.
            home.activation.copyWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
                if [ ! -f ${config.home.homeDirectory}/stuff/wallpaper.png ]; then
                  mkdir -p ${config.home.homeDirectory}/stuff
                  cp ${./cat-waves.png} ${config.home.homeDirectory}/stuff/wallpaper.png
                fi
            '';

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
