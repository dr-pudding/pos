#!/usr/bin/env sh

# Create the root flake.nix system configuration file.
echo \
'{
    description = "puddingOS";
    inputs = {
        pos.url = "github:dr-pudding/pos/main";
        nixpkgs.follows = "pos/nixpkgs";
    };
    outputs = { pos, ... }: {
        nixosConfigurations.Thonkpad = (pos.nixosConfigurations.makeSystem {
            username = "jack";
        }).extendModules {
            modules = [ 
                { networking.hostName = "Thonkpad"; }
                ./hardware-configuration.nix
            ];
        };
    };
}'\
    > /etc/nixos/flake.nix

# Rebuild the NixOS configuration.
nixos-rebuild switch -v
