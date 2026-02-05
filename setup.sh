#!/usr/bin/env sh

# create the root flake.nix system configuration file.
echo \
'{
    description = "puddingos";

    inputs = {
        pos.url = "github:dr-pudding/pos/main";
        nixpkgs.follows = "pos/nixpkgs";
    };

    outputs = { pos, ... }: {
        nixosconfigurations.puddingOS = (pos.nixosconfigurations.makesystem {
            username = "jack";
        }).extendmodules {
            modules = [ 
                { networking.hostname = "puddingOS"; }
                ./hardware-configuration.nix
            ];
        };
    };
}'\
    > /etc/nixos/flake.nix

# rebuild the nixos configuration.
sudo env nix_config="experimental-features = nix-command flakes" nixos-rebuild switch '#puddingOS'
