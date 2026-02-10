#!/usr/bin/env sh


# Ensure running with sudo.
if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo."
    exit 1
fi
ACTUAL_USER=$SUDO_USER

# Ensure internet connection.
 if ! ping -c 1 8.8.8.8 &> /dev/null; then
     echo "No internet connection detected."
     exit 1
 fi

# Detect if running NixOS.
if [ -f /etc/NIXOS ]; then
    IS_NIXOS=true
else
    # TODO: Implement standalone home-manager installation.
    echo "Automated installation on non-NixOS systems is not yet supported."
    exit 1
fi

# Prompt for installation type.
echo "puddingOS has two modules: system configuration (boot, drivers, etc.) and home configuration (applications and utilities). Which modules would you like to install?"
echo "1) system module only"
echo "2) home module only"  
echo "3) both system and home modules"
read -p "Enter choice [3]: " INSTALL_CHOICE </dev/tty
INSTALL_CHOICE=${INSTALL_CHOICE:-3}

# Validate choice.
case $INSTALL_CHOICE in
    1) INSTALL_SYSTEM=true; INSTALL_HOME=false ;;
    2) INSTALL_SYSTEM=false; INSTALL_HOME=true ;;
    3) INSTALL_SYSTEM=true; INSTALL_HOME=true ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# Prompt for hostname with default. # TODO: Use the current hostname as the default instead.
read -p "Enter hostname for this system [puddingOS]: " HOSTNAME </dev/tty
HOSTNAME=${HOSTNAME:-puddingOS}

# Prompt for development mode.
echo "By default, puddingOS is pulled from the remote Git repository directly into the Nix store, which is readonly. If you want to develop/modify puddingOS locally, it must be cloned separately to an accessible location and loaded by its local path. Note that if you enable this, you will have to manually pull and merge from the remote repository in order to update puddingOS."
read -p "Use local development mode? [y/N]: " DEV_MODE </dev/tty
DEV_MODE=${DEV_MODE:-n}

if [ "$DEV_MODE" = "y" ] || [ "$DEV_MODE" = "Y" ]; then
    if [ -d "/home/$ACTUAL_USER/.pos" ]; then
        echo "Directory /home/$ACTUAL_USER/.pos already exists, skipping clone."
    else
        if ! command -v git &> /dev/null; then
            echo "Cloning for local development requires git. On NixOS, you can run 'nix-shell -p git' to quickly enter a temporary shell with git installed."
            exit 1
        fi
        echo "Cloning pos repository (dev branch) to /home/$ACTUAL_USER/.pos..."
        git clone -b dev https://github.com/dr-pudding/pos.git /home/$ACTUAL_USER/.pos
        chown -R $ACTUAL_USER:users /home/$ACTUAL_USER/.pos
    fi
    POS_SYSTEM_URL="path:/home/$ACTUAL_USER/.pos/system"
    POS_HOME_URL="path:/home/$ACTUAL_USER/.pos/home"
else
    POS_SYSTEM_URL="github:dr-pudding/pos/main?dir=system"
    POS_HOME_URL="github:dr-pudding/pos/main?dir=home"
fi

# Detect EFI vs BIOS (only if installing system)
if [ "$INSTALL_SYSTEM" = true ]; then
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="efi"
        echo "Detected EFI boot mode."
    else
        BOOT_MODE="bios"
        echo "Detected BIOS boot mode."
        read -p "Enter boot device for GRUB [/dev/sda]: " BOOT_DEVICE </dev/tty
        BOOT_DEVICE=${BOOT_DEVICE:-/dev/sda}
    fi
    
    if [ "$BOOT_MODE" = "efi" ]; then
        BOOT_CONFIG="{ }"
    else
        BOOT_CONFIG="{ boot.loader.grub.device = \"$BOOT_DEVICE\"; boot.loader.grub.efiSupport = false; }"
    fi
fi

# Build flake.nix based on what's being installed.
if [ "$INSTALL_SYSTEM" = true ] && [ "$INSTALL_HOME" = true ]; then
    # Both system and home.
    FLAKE_CONTENT="{
    description = \"puddingos\";

    inputs = {
        pos-system.url = \"$POS_SYSTEM_URL\";
        pos-home.url = \"$POS_HOME_URL\";
        nixpkgs.follows = \"pos-system/nixpkgs\";
        home-manager.follows = \"pos-home/home-manager\";
    };

    outputs = { pos-system, pos-home, home-manager, ... }: {
        nixosConfigurations.${HOSTNAME} = (pos-system.nixosConfigurations.makeSystem {
            username = \"$ACTUAL_USER\";
        }).extendModules {
            modules = [
                home-manager.nixosModules.home-manager
                {
                    networking.hostName = \"${HOSTNAME}\";
                    time.timeZone = \"America/Chicago\";
                    
                    home-manager = {
                        useGlobalPkgs = true;
                        useUserPackages = true;
                        users.${ACTUAL_USER}.imports = pos-home.homeModules.default {
                            username = \"$ACTUAL_USER\";
                        };
                    };
                }
                ./hardware-configuration.nix
                $BOOT_CONFIG
            ];
        };
    };
}"
elif [ "$INSTALL_SYSTEM" = true ]; then
    # System only.
    FLAKE_CONTENT="{
    description = \"puddingos\";

    inputs = {
        pos-system.url = \"$POS_SYSTEM_URL\";
        nixpkgs.follows = \"pos-system/nixpkgs\";
    };

    outputs = { pos-system, ... }: {
        nixosConfigurations.${HOSTNAME} = (pos-system.nixosConfigurations.makeSystem {
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
}"
else
    # Home only - integrate into existing NixOS config.
    FLAKE_CONTENT="{
    description = \"puddingos\";

    inputs = {
        nixpkgs.url = \"github:NixOS/nixpkgs/nixos-25.11\";
        pos-home.url = \"$POS_HOME_URL\";
        home-manager.follows = \"pos-home/home-manager\";
    };

    outputs = { nixpkgs, pos-home, home-manager, ... }: {
        nixosConfigurations.${HOSTNAME} = nixpkgs.lib.nixosSystem {
            system = \"x86_64-linux\";
            modules = [
                home-manager.nixosModules.home-manager
                ./hardware-configuration.nix
                {
                    networking.hostName = \"${HOSTNAME}\";
                    system.stateVersion = \"25.11\";
                    
                    users.users.${ACTUAL_USER} = {
                        isNormalUser = true;
                        home = \"/home/${ACTUAL_USER}\";
                        extraGroups = [\"wheel\"];
                    };
                    
                    home-manager = {
                        useGlobalPkgs = true;
                        useUserPackages = true;
                        users.${ACTUAL_USER}.imports = pos-home.homeModules.default {
                            username = \"$ACTUAL_USER\";
                        };
                    };
                }
            ];
        };
    };
}"
fi

echo "$FLAKE_CONTENT" > /etc/nixos/flake.nix

# Clear flake lock.
rm -f /etc/nixos/flake.lock

# Set the hostname.
hostname "$HOSTNAME"

# Rebuild the system to apply the installation.
env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch
