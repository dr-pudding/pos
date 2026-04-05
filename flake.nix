{
    description = "puddingOS - A high-level configuration layer for NixOS and Home Manager.";

    inputs = {
        authentik-nix.url = "github:nix-community/authentik-nix";
    };

    outputs = {
        self,
        authentik-nix,
    }: {
        nixosModules.default = import ./modules/nixos;
        nixosModules.server = {pkgs, ...}: {
            imports = [authentik-nix.nixosModules.default];
        };
        homeManagerModules.default = import ./modules/home-manager;
    };
}
