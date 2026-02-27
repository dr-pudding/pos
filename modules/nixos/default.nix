{
    config,
    lib,
    pkgs,
    ...
}: let
    pos-cmd = pkgs.callPackage ./cmd {};
    catppuccin = builtins.fetchTarball {
        url = "https://github.com/catppuccin/nix/archive/release-25.11.tar.gz";
        sha256 = "0p9v37l8fvm15ziig45ragqfk581584mgl425v1nkqrnkafzl8i3";
    };
in {
    # Import dependencies and submodules.
    imports = [
        "${catppuccin}/modules/nixos"
        ./grub.nix
    ];

    # Configuration for toggling puddingOS and other submodules.
    options.pos = {
        enable = lib.mkEnableOption "Enable puddingOS core module and most submodules.";

        sddm.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable display manager and login greeter.";
        };

        hypr.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable window manager and desktop environment.";
        };
    };

    config = lib.mkMerge [
        # Core module (base configuration).
        (lib.mkIf config.pos.enable {
            environment.systemPackages = [pos-cmd];

            # OpenGL drivers with legacy support.
            hardware.graphics = {
                enable = true;
                enable32Bit = true;
            };

            # Unified color and styling for system applications.
            catppuccin = {
           #     enable = true;
                flavor = "macchiato";
                accent = "lavender";
                tty.enable = true;
            };

            # Main font set for system applications.
            fonts.packages = [pkgs.nerd-fonts.overpass];
        })

        # SDDM module (display manager).
        (lib.mkIf (config.pos.sddm.enable && config.pos.enable) {
            services.displayManager.sddm = {
                enable = true;
                wayland.enable = true;
                package = pkgs.kdePackages.sddm;
            };

            catppuccin.sddm = {
                enable = true;
                font = "OverpassMNerdFont";
                fontSize = "12";
            };
        })

        # Hyprland module (desktop environment).
        (lib.mkIf (config.pos.hypr.enable
            && config.pos.enable) {
            programs.hyprland = {
                enable = true;
                xwayland.enable = true;
            };

            # Used to tell the puddingOS home-manager module to enable Hyprland config.
            environment.sessionVariables.POS_HYPR = "true";
        })
    ];
}
