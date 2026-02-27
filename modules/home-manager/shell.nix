{
    pkgs,
    config,
    lib,
    ...
}:
with lib; {
    options.pos.shell = {
        enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable shell configurations and terminal emulator.";
        };
    };

    config = mkIf (config.pos.shell.enable
        && config.pos.enable) {
        programs.fish = {
            enable = true;

            # Use fish for nix-shell.
            shellAliases.nix-shell = "nix-shell --run fish";
        };
        catppuccin.fish.enable = true;

        # Default shell behaviour for fish (see https://nixos.wiki/wiki/Fish).
        programs.bash = {
            enable = true;
            initExtra = ''
                if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
                then
                  shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
                  exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
                fi
            '';
        };

        # Improved ls command
        programs.lsd = {
            enable = true;
            enableFishIntegration = true;
            icons.filetype = {
                "dir" = "󰉋";
            };
            icons.name = {
                #"system" = "";
            };
        };
        catppuccin.lsd.enable = true;

        # Version control
        programs.git = {
            enable = true;
            extraConfig = {
                init.defaultBranch = "main";
                core.askpass = "";
            };
        };

        # Password management
        programs.password-store = {
            enable = true;
            settings.PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.pass";
        };

        # Improved cat command and pager.
        programs.bat.enable = true;
        programs.fish.shellAliases.cat = "bat -pp";
        catppuccin.bat.enable = true;

        # Improved command history system.
        programs.atuin.enable = true;
        catppuccin.atuin.enable = true;

        # System monitor.
        programs.bottom.enable = true;
        catppuccin.bottom.enable = true;

        # Graphical terminal emulator.
        programs.alacritty = {
            enable = true;
            settings = {
                window.opacity = 0.9;
                font = {
                    size = 12;
                    normal.family = "OverpassM Nerd Font";
                };
            };
        };
        catppuccin.alacritty.enable = true;
    };
}
