{pkgs, ...}: {
    # Use fish as the main terminal shell.
    programs.fish = {
        enable = true;

        shellAliases = {
            # Basic shortcuts.
            svi = "sudo -E nvim";
        };
    };

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

    # Improved command history system.
    programs.atuin.enable = true;
}
