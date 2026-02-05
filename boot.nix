{lib, ...}: {
    boot = {
        loader = {
            grub = {
                enable = true;
                useOSProber = true;

                # Install as removable allows maintanence from a live image.
                efiInstallAsRemovable = false;
                gfxmodeEfi = "1920x1080";

                # Default to EFI, can be override if using BIOS.
                efiSupport = lib.mkDefaultrue;
                device = lib.mkDefault "nodev";
            };

            # Required for EFI boot (I think...?)
            efi.canTouchEfiVariables = true;

            # Hide the bootloader OS selector by default.
            timeout = 5;
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

        # Necessary for VirtualBox.
        blacklistedKernelModules = ["kvm-intel"];
    };
}
