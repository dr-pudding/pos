#!/usr/bin/env sh

# Prompt for hostname with default.
read -p "Enter hostname for this system [puddingOS]: " HOSTNAME </dev/tty
HOSTNAME=${HOSTNAME:-puddingOS}

# Detect EFI vs BIOS.
if [ -d /sys/firmware/efi ]; then
    BOOT_MODE="efi"
    echo "Detected EFI boot mode"
else
    BOOT_MODE="bios"
    echo "Detected BIOS boot mode"
    # Prompt for boot device with default.
    read -p "Enter boot device for GRUB [/dev/sda]: " BOOT_DEVICE </dev/tty
    BOOT_DEVICE=${BOOT_DEVICE:-/dev/sda}
fi

# Create the root flake.nix system configuration file.
if [ "$BOOT_MODE" = "efi" ]; then
    BOOT_CONFIG="{ }"
else
    BOOT_CONFIG="{ boot.loader.grub.device = \"$BOOT_DEVICE\"; boot.loader.grub.efiSupport = false; }"
fi

echo \
"{
    description = \"puddingos\";
    inputs = {
        pos.url = \"github:dr-pudding/pos/dev\";
        nixpkgs.follows = \"pos/nixpkgs\";
    };
    outputs = { pos, ... }: {
        nixosConfigurations.${HOSTNAME} = (pos.nixosConfigurations.makeSystem {
            username = \"jack\";
        }).extendModules {
            modules = [ 
                { networking.hostName = \"${HOSTNAME}\"; }
                ./hardware-configuration.nix
                $BOOT_CONFIG
            ];
        };
    };
}"\
    > /etc/nixos/flake.nix

# Clear flake lock.
sudo rm -f /etc/nixos/flake.lock

# Set the hostname immediately so nixos-rebuild can match it.
sudo hostname "$HOSTNAME"

# Rebuild the nixos configuration.
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch

echo "Installation complete. Reboot is recommended."
