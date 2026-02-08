#!/usr/bin/env sh

# Ensure running with sudo.
if [ -z "$SUDO_USER" ]; then
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo ./setup.sh"
    exit 1
fi

# Get the actual user (not root when using sudo).
ACTUAL_USER=$SUDO_USER

# Prompt for hostname with default.
read -p "Enter hostname for this system [puddingOS]: " HOSTNAME </dev/tty
HOSTNAME=${HOSTNAME:-puddingOS}

# Prompt for development mode.
read -p "Use local development mode (clone dev branch locally and build from /home/$ACTUAL_USER/.pos)? [y/N]: " DEV_MODE </dev/tty
DEV_MODE=${DEV_MODE:-n}

if [ "$DEV_MODE" = "y" ] || [ "$DEV_MODE" = "Y" ]; then
    echo "Cloning pos repository (dev branch) to /home/$ACTUAL_USER/.pos..."
    git clone -b dev https://github.com/dr-pudding/pos.git /home/$ACTUAL_USER/.pos
    chown -R $ACTUAL_USER:users /home/$ACTUAL_USER/.pos
    POS_URL="path:/home/$ACTUAL_USER/.pos"
else
    POS_URL="github:dr-pudding/pos/main"
fi

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

# /etc/nixos/flake.nix
echo \
"{
    description = \"puddingos\";
    inputs = {
        pos.url = \"$POS_URL\";
        nixpkgs.follows = \"pos/nixpkgs\";
    };
    outputs = { pos, ... }: {
        nixosConfigurations.${HOSTNAME} = (pos.nixosConfigurations.makeSystem {
            username = \"$ACTUAL_USER\";
        }).extendModules {
            modules = [ 
                {
                    networking.hostName = \"${HOSTNAME}\";
                    time.timeZone = \"America/Chicago\";
                }
                ./hardware-configuration.nix
                $BOOT_CONFIG
            ];
        };
    };
}"\
    > /etc/nixos/flake.nix

# Clear flake lock.
rm -f /etc/nixos/flake.lock

# Set the hostname immediately so nixos-rebuild can match it.
hostname "$HOSTNAME"

# Rebuild the nixos configuration.
env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch
