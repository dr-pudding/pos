{
    inputs = {
        nixvim = {
            url = "github:nix-community/nixvim/nixos-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nixpkgs.follows = "nixpkgs";
    };

    outputs = {nixvim, ...}: {
        homeManagerModules.default = {
            imports = [
                # Text editor.
                nixvim.homeManagerModules.nixvim
                ./vi.nix
            ];
        };
    };
}
