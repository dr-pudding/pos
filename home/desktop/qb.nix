{...}: {
    programs.qutebrowser = {
        enable = true;

        keyBindings.normal = {
            # Basic usage/navigation.
            "<Ctrl+r>" = "forward";
            "<u>" = "back";
            "<U>" = "undo";
        };

        settings = {
            content = {
                plugins = true;

                # Allow copy on-click.
                javascript.clipboard = "access-paste";
            };

            # Use custom download directory.
            downloads.location.directory = "~/stuff/downloads";

            # Apply style customizations.
            colors = {
                webpage.darkmode.enabled = false;
                webpage.preferred_color_scheme = "dark";
            };

            fonts = {
                default_family = "OverpassM Nerd Font";
                default_size = "12pt";
            };
        };
    };

    # Define a shell alias to launch the browser slightly faster.
    programs.fish.shellAliases.qb = "qutebrowser";
}
