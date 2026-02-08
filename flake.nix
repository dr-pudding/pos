{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

        #home-manager = {
        #    url = "github:nix-community/home-manager/release-25.11";
        #    inputs.nixpkgs.follows = "nixpkgs";
        #};

        #catppuccin.url = "github:catppuccin/nix/release-25.11";
    };

    outputs = {
        nixpkgs,
        #home-manager,
        #catppuccin,
        ...
    }: {
        nixosConfigurations.makeSystem = {username}:
            nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./system.nix

                    {
                        users.users.${username} = {
                            isNormalUser = true;
                            extraGroups = ["wheel"];
                        };

                        system.stateVersion = "25.11";
                    }
                ];
            };
    };
}
