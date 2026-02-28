{
    pkgs,
    config,
    lib,
    ...
}:
with lib; {
    options.pos.steam = {
        enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Steam with Gamescope session.";
        };
    };

    config = mkIf (config.pos.steam.enable
        && config.pos.enable) {
        programs = {
            # Main desktop gaming platform.
            steam = {
                enable = true;
                gamescopeSession.enable = true;
                remotePlay.openFirewall = true;
                dedicatedServer.openFirewall = true;
                localNetworkGameTransfers.openFirewall = true;
            };

            # Isolated graphical environment for gaming.
            gamescope = {
                enable = true;
                capSysNice = true;
            };
        };

        # Create a script to launch gamescope session via TTY.
        environment.systemPackages = with pkgs; [
            gamescope-wsi # Required for extended Windows features like HDR.
            (pkgs.writeScriptBin "gslaunch" ''
                #!/usr/bin/env bash
                set -xeuo pipefail

                gamescopeArgs=(
                    --adaptive-sync
                    --hdr-enabled
                    --rt
                    --steam
                )

                steamArgs=(
                    -pipewire-dmabuf
                    -tenfoot
                )

                exec gamescope "''${gamescopeArgs[@]}" -- steam "''${steamArgs[@]}"
            '')
        ];
    };
}
