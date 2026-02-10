{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        catppuccin.url = "github:catppuccin/nix/release-25.11";
        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = { nixpkgs, home-manager, catppuccin, ... }: {
        homeConfigurations.makeHome = { username }: 
            home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages.x86_64-linux;
                    modules = [
                        catppuccin.homeManagerModules.default
                        ./home.nix
                        
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
            };
      };
}
