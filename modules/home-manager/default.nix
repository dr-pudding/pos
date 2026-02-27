{lib, ...}:
#with lib;
let
    catppuccin = builtins.fetchTarball {
        url = "https://github.com/catppuccin/nix/archive/release-25.11.tar.gz";
        sha256 = "0p9v37l8fvm15ziig45ragqfk581584mgl425v1nkqrnkafzl8i3";
    };
in {
    # Import dependencies and submodules.
    imports = [
        (catppuccin + "/modules/home-manager")
        ./mangohud.nix
        ./shell.nix
        ./qb.nix
        ./hypr
        ./vi
    ];

    # Configuration for toggling puddingOS and other submodules.
    options.pos = {
        enable = lib.mkEnableOption "Enable puddingOS core module and most submodules.";
    };

    # config = lib.mkMerge [
    # Core module (base configuration).
    #    (lib.mkIf config.pos.enable {
    #         catppuccin = {
    #              flavor = "macchiato";
    #               accent = "lavender";
    #            };
    #        })
    #    ];
}
