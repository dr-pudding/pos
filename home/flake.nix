{
    inputs = {
        # External flake imports.
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        catppuccin.url = "github:catppuccin/nix/release-25.11";
        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Local/nested flake imports.
        shell = {
            url = "path:./shell";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = {
        nixpkgs,
        home-manager,
        catppuccin,
        shell,
        ...
    }: let
        modules = username: [
            catppuccin.homeModules.default # Colorscheme and styling.
            shell.homeManagerModules.default # Install and configure CLI applications.

            {
                home = {
                    username = username;
                    homeDirectory = "/home/${username}";
                    stateVersion = "25.11";
                };

                catppuccin = {
                    enable = true;
                    flavor = "macchiato";
                    accent = "lavender";
                };
            }
        ];
    in {
        # For standalone home-manager.
        homeConfigurations.makeHome = {username}:
            home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages.x86_64-linux;
                modules = modules username;
            };

        # For NixOS module integration.
        homeModules.default = {username}: modules username;
    };
}
