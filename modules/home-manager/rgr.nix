{
    pkgs,
    config,
    lib,
    ...
}:
with lib; {
    options.pos.rgr = {
        enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable vim-like file explorer.";
        };
    };

    config = mkIf (config.pos.rgr.enable
        && config.pos.enable) {
        programs.ranger = {
            enable = true;

            plugins = [
                {
                    name = "devicons";
                    src = builtins.fetchGit {
                        url = "https://github.com/alexanderjeurissen/ranger_devicons.git";
                        rev = "1bcaff0366a9d345313dc5af14002cfdcddabb82";
                    };
                }
            ];

            settings = {
                preview_images = true;
                preview_images_method = "ueberzug";
            };

            extraConfig = "default_linemode devicons";
        };

        # In-terminal image preview
        home.packages = with pkgs; [
            ueberzugpp
        ];

        programs.fish = {
            shellAlias.rgr = "ranger";
            interactiveShellInit = ''
                function rcd
                    set tmpfile (mktemp)
                    ranger --choosedir=$tmpfile $argv
                    if test -s $tmpfile
                        set dest (cat $tmpfile)
                        if test -d "$dest"
                            cd "$dest"
                        end
                    end
                    rm -f $tmpfile
                end
            '';
        };
    };
}
