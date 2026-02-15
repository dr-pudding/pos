{
    pkgs,
    lib,
    ...
}: {
    # Boot configuration.
    boot = {
        loader = {
            grub = {
                enable = true;
                useOSProber = false;

                # Install as removable allows maintanence from a live image.
                efiInstallAsRemovable = false;
                gfxmodeEfi = "1920x1080";

                # Default to EFI, can be override if using BIOS.
                efiSupport = lib.mkDefault true;
                device = lib.mkDefault "nodev";

                configurationName = "puddingOS";
            };

            # Required for EFI boot (I think...?)
            efi.canTouchEfiVariables = true;
        };

        # Enable silent boot.
        consoleLogLevel = 3;
        initrd.verbose = false;
        kernelParams = [
            "quiet"
            "splash"
            "boot.shell_on_fail"
            "udev.log_priority=3"
            "rd.systemd.show_status=auto"
        ];
    };

    # OpenGL drivers with legacy support.
    hardware.graphics = {
        enable = true;
        enable32Bit = true;
    };

    # System services.
    services = {
        # Display manager/login greeter.
        displayManager.sddm = {
            enable = true;
            wayland.enable = true;
            package = pkgs.kdePackages.sddm;
        };

        # Used by gamescope and certain other applications.
        xserver.enable = true;
    };

    # Primary window manager/desktop environment base.
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };

    # Colorscheme and style customizations.
    catppuccin = {
        enable = true;
        flavor = "macchiato";
        accent = "lavender";

        grub.enable = true;
        tty.enable = true;

        sddm = {
            enable = true;
            font = "OverpassMNerdFont";
            fontSize = "12";
        };
    };

    # Main font set for system applications.
    fonts.packages = [pkgs.nerd-fonts.overpass];
}
