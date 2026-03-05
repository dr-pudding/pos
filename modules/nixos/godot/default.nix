{
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

        remoteDebug.enable = mkOption {
            type = types.bool;
            default = false;
            description = "Open firewall ports for remote debugging.";
        };
    };

    config = mkIf (config.pos.godot.enable && config.pos.enable) {
        environment.systemPackages = with pkgs; [
            godot
        ];

        networking.firewall = mkIf config.pos.godot.remoteDebug.enable {
            allowedTCPPorts = [6007 6008];
            allowedUDPPorts = [6007 6008];
        };
    };
}
