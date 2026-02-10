{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        catppuccin.url = "github:catppuccin/nix/release-25.11";
    };

    outputs = {
        nixpkgs,
        catppuccin,
        ...
    }: {
        nixosConfigurations.makeSystem = {username}:
            nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";

                modules = [
                    catppuccin.nixosModules.default
                    ./system.nix

                    {
                        users.users.${username} = {
                            isNormalUser = true;
                            extraGroups = ["wheel"];
                        };

			nix.settings.experimental-features = ["nix-command" "flakes"];
                        system.stateVersion = "25.11";
                    }
                ];
            };
    };
}
