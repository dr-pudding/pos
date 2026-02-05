{
    boot = {
        loader = {
            grub = {
                enable = true;
                useOSProber = true;
                device = "nodev";

                efiSupport = true;
                efiInstallAsRemovable = false;

                gfxmodeEfi = "1920x1080";
            };

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

        # Hide the bootloader OS selector by default.
        loader.timeout = 5;

        # Necessary for VirtualBox.
        blacklistedKernelModules = ["kvm-intel"];
    };
}
