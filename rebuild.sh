#!/usr/bin/env sh

sudo nix flake update --flake /etc/nixos
sudo nixos-rebuild switch
