# Installation
There are several routes to installing puddingOS on your system depending on what you need. The first thing to understand is that it is composed of two independent parts: a NixOS module and a Home Manager module. The Home Manager module is treated as the default for most configurations, with the NixOS module only being used whenever system-level configuration is absolutely necessary (such as with the Grub and Limine submodules).

The Home Manager module can be installed on any Linux system that supports the Nix package manager, provided you are able to use it to install the standalone version of Home Manager. In theory it should work with nix-darwin as well, but this has not been tested. If you want to use the system-level NixOS module, you will need a machine that is actively running NixOS.

## Stable Nix Installation
You can install and import one or both modules into your existing Nix configurations:

```nix
{ ... }: let
    pos = builtins.fetchTarball {
        url = "https://github.com/dr-pudding/pos/archive/release-25.11.tar.gz";
    };

    # Optional: required for puddingOS home-manager module.
    home-manager = builtins.fetchTarball {
        url = "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
    };
in {
    imports = [ "${pos}/modules/nixos" ];
    pos.enable = true;

    home-manager.users.USERNAME = {
        imports = [ "${pos}/modules/home-manager" ];
        pos.enable = true;
    };
}
```

### Local Clone Import
The configuration above is written with the assumption that you are are purely a user and are not making any changes to the puddingOS configuration directly. If you want to develop/modify puddingOS (beyond just overriding it from your own configurations), you will need to clone the repository manually:

```sh
git clone https://github.com/dr-pudding/pos /home/USERNAME/.pos
```

and then import the modules directly from their local paths rather than URLs:

```nix
imports = [ /home/USERNAME/.pos/modules/nixos ];
home-manager.users.USERNAME.imports = [ /home/USERNAME/.pos/modules/home-manager ];
```

## Flakes Installation
Flakes is not yet officially supported (i.e. I haven't made a flake.nix yet), but it is a high priority change that should be made relatively soon. In the meantime, you can still use the modules as inputs the way you normally would if you already have a Flakes-based system.

