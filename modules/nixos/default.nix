{
    config,
    lib,
    pkgs,
    ...
}: let
    cfg = config.pos;

    # Create a package for the pos CLI utility.
    pythonWithPackages = pkgs.python3.withPackages (ps: [ps.click]);
    pos-cmd = pkgs.stdenv.mkDerivation {
        name = "pos";
        src = ./.;
        buildInputs = [pythonWithPackages];
        nativeBuildInputs = [pkgs.makeWrapper];
        installPhase = ''
            # Copy Python module.
            mkdir -p $out/bin $out/lib/pos
            cp pos_cmd.py $out/lib/pos/

            # Create wrapper for the pos command.
            cat > $out/bin/pos << EOF
            #!${pythonWithPackages}/bin/python3
            import sys
            sys.path.insert(0, "$out/lib/pos")
            exec(open("$out/lib/pos/pos_cmd.py").read())
            EOF
            chmod +x $out/bin/pos
        '';
    };

    # Install styling library for various applications.
    catppuccin = builtins.fetchTarball {
        url = "https://github.com/catppuccin/nix/archive/release-25.11.tar.gz";
        sha256 = "0p9v37l8fvm15ziig45ragqfk581584mgl425v1nkqrnkafzl8i3";
    };
in {
    # Import dependencies and submodules.
    imports = [
        "${catppuccin}/modules/nixos"
        ./sessions.nix
        ./grub
        ./limine
        ./godot
        ./steam
    ];

    # Configuration for toggling puddingOS and other submodules.
    options.pos = {
        enable = lib.mkEnableOption "Enable puddingOS core module and most submodules.";

        sddm.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable display manager and login greeter.";
        };

        hypr.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable window manager and desktop environment.";
        };
    };

    config = lib.mkMerge [
        # Core module (base configuration).
        (lib.mkIf cfg.enable {
            environment.systemPackages = [pos-cmd];

            # OpenGL drivers with legacy support.
            hardware.graphics = {
                enable = true;
                enable32Bit = true;
            };

            # Pipewire audio drivers with PulseAudio support.
            services.pipewire = {
                enable = true;
                pulse.enable = true;
            };

            # Unified color and styling for system applications.
            catppuccin = {
                flavor = "macchiato";
                accent = "lavender";
                tty.enable = true;
            };

            # Main font set for system applications.
            fonts.packages = [pkgs.nerd-fonts.overpass];
        })

        # SDDM module (display manager).
        (lib.mkIf (cfg.sddm.enable && cfg.enable) {
            services.displayManager.sddm = {
                enable = true;
                wayland.enable = true;
                package = pkgs.kdePackages.sddm;
            };

            catppuccin.sddm = {
                enable = true;
                font = "OverpassMNerdFont";
                fontSize = "12";
            };
        })

        # Hyprland module (desktop environment).
        (lib.mkIf (cfg.hypr.enable && cfg.enable) {
            programs.hyprland = {
                enable = true;
                xwayland.enable = true;
            };
        })
    ];
}
