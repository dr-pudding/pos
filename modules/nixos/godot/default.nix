{
    pkgs,
    config,
    lib,
    ...
}:
with lib; {
    options.pos.godot = {
        enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable the latest version of Godot Engine.";
        };

        enableRemoteDebug = mkOption {
            type = types.bool;
            default = false;
            description = "Open ports 6007 and 6008 for remote debugging.";
        };
    };

    config = mkIf (config.pos.godot.enable && config.pos.enable) {
        environment.systemPackages = with pkgs; [
            godot # Current version of Godot Engine.
        ];

        networking.firewall = mkIf config.pos.godot.enableRemoteDebug {
            allowedTCPPorts = [6007 6008];
            allowedUDPPorts = [6007 6008];
        };
    };
}
