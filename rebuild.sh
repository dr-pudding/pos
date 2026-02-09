#!/usr/bin/env sh

sudo nix flake update /etc/nixos
env NIX_CONFIG="experimental-features = flakes" sudo nixos-rebuild switch
