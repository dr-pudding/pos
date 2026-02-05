#!/usr/bin/env sh

# Prompt for hostname with default.
read -p "Enter hostname for this system [puddingOS]: " HOSTNAME </dev/tty
HOSTNAME=${HOSTNAME:-puddingOS}

# Create the root flake.nix system configuration file.
echo \
"{
    description = \"puddingos\";
    inputs = {
        pos.url = \"github:dr-pudding/pos/main\";
        nixpkgs.follows = \"pos/nixpkgs\";
    };
    outputs = { pos, ... }: {
        nixosConfigurations.${HOSTNAME} = (pos.nixosConfigurations.makeSystem {
            username = \"jack\";
        }).extendModules {
            modules = [ 
                { networking.hostName = \"${HOSTNAME}\"; }
                ./hardware-configuration.nix
            ];
        };
    };
}"\
    > /etc/nixos/flake.nix

# Set the hostname immediately so nixos-rebuild can match it.
sudo hostname "$HOSTNAME"

# Rebuild the nixos configuration.
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch
