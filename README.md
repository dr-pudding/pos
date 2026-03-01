# puddingOS
A modular set of Nix configurations containing an all-in-one OS and desktop environment. These are basically just my dotfiles that I made public because it makes working with flakes a bit easier, but for the sake of good practice I decided to organize them in such a way that anyone can install and use different parts of it depending on their exact needs.

## Installation
You will need a working installation of NixOS if you do not have one already. Please see the [NixOS Installation Guide](https://nixos.wiki/wiki/NixOS_Installation_Guide) if you need help. Just make sure your installation has:

- A primary user with sudo access.
- An internet connection.

Once these conditions are met, you can install and configure puddingOS on top of your existing system. There are two primary modules, a NixOS module (which can only run on NixOS systems) and a home-manager module (which can theoretically run on any system with a standalone home-manager setup). They can be installed simultaneously or individually.

### Stable Nix Installation
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

## Submodule Configuration
In order to be accommodating to the needs of multiple different systems, puddingOS is composed of several submodules that can be enabled and configured separately from one another. For example:

```nix
{
    pos.enable = true;
    pos.grub.enable = true;
    pos.grub.device = "/dev/sda";
};
```

This would allow you to automatically install and configure a working Grub setup. Many submodules, such as this one, have additional configuration options. For example, setting `pos.grub.device` will change from EFI to BIOS boot mode, and use the value as the boot device.

Note that `pos.enable = true` must also be set as a prerequisite, or `pos.grub.enable = true` will have no effect. This logic holds true for the entire tree of submodules. If a parent module is disabled, all of its child submodules will be disabled as well.

The following sections list all puddingOS submodules and their configuration options. Remember that puddingOS itself is composed of a NixOS module and a home-manager module, so their submodules are separate as well.

### NixOS submodules
#### pos core
When `pos.enable = true` is set, a few things will be enabled by default. This includes basic audio/video drivers, Catppuccin color setup, font packages, etc.

#### grub
When `pos.grub.enable = true` is set, a full working configuration for the Grub bootloader will be enabled, complete with os-prober scanning. By default it will use EFI mode and autodetect the boot device, but it can be changed to BIOS mode by setting `pos.grub.device` to the drive you would like to use as the boot device.

#### sddm
When `pos.sddm.enable = true` is set, the SDDM display manager will be installed on started on boot.

#### hypr
When `pos.hypr.enable = true` is set, the Hyprland tiling window manager will be installed and made selectable as a session by display managers. Since actual configuration of Hyprland happens on the user end, you will also need to enable the corresponding home-manager submodule to make full use of this.

#### steam
When `pos.steam.enable = true` is set, several things will happen. Firstly, the Steam client will be installed and firewall ports will be opened for remote play and local network transfers. More significantly, it will give you access to a new command, `startgs`, which can be used in a TTY to start Gamescope as a standalone X11 session. In simple terms, this is essentially running Big Picture Mode as a minimal desktop environment, similarly to what the Steam Deck does. In addition to providing a console-like interface, it also enables certain extended compatibility features for running Windows applications, such as HDR support for Steam games running through Proton.

There are also some other miscellaneous configurations designed to improve gaming experience on NixOS, such as configuring drivers and kernel modules to support wireless Xbox controllers.

#### godot
When `pos.godot.enable = true`, the only thing that will happen by default is that the latest version of the Godot game engine will be installed. The stable Nix package for Godot is often slow to receive updates, so using this module will ensure that it is updated up to the current minor version (i.e. 4.1 -> 4.2 but not necessarily 4.1.0 -> 4.1.1).

Additionally, you can optionally set `pos.godot.remoteDebug.enable = true` to open up firewall ports for remote debugging. By default, these are ports 6007 and 6008 over UDP and TCP. If you want to use a non-default port, you will have to change it in the Godot editor settings and then manually open the firewall ports in your NixOS configuration.

### home-manager submodules
#### pos core
When `pos.enable = true` is set, nothing will happen by default. It is only used to toggle the rest of the submodules at once.

#### shell + shell.rgr
When `pos.shell.enable = true` is set, the fish shell will be enabled and set as the default for that user. Several other shell features will be enabled aswell, such as a new command history system, improved core utilities, password management, and more. It also installs a terminal emulator, Alacritty, which can be used to interact with the shell in graphical sessions.

When `pos.rgr.enable = true` is set, the ranger file explorer will be installed and made accessible via the `rgr` shell alias. Additionally, it will create a new fish function, `rcd` (ranger + cd), which can be run from the command line as usual. It works identically to the normal ranger command, with one exception: after closing the ranger session, you will return to a shell in whichever directory you left ranger in. In other words, it lets you use ranger to cd into a directory using the interface of a file explorer.

#### vi
When `pos.vi.enable = true` is set, Neovim will be installed and configured using the Nixvim module. This contains a complete starter setup for Neovim, including LSPs for several languages, clipboard integration, autoformatting, and several other features and plugins. Enabling this submodule will also create two fish shell aliases: `vi` which is simply a shortcut for `nvim`, and `svi` which will allow editing with root permissions while still maintaining userspace Neovim configurations.

Keep in mind that text editor configurations are very individualized, and there are a few somewhat opinionated configurations included in this module, such as:

- tab width of 4 spaces
- autoformat on file write
- overriden keybinds: `?`, `\``, `~` 
    - The `?` character was formerly used as a backwards search, but this can be achieved by using `N` rather than `n` with a normal search.
        - Now it is used for live grep, i.e. search in files.
    - The `\`` character was formerly used for jumping to a set mark. I disabled it because I didn't use the marks system, so this one may not be for everyone.
        - Now it is used to swap between open files on the current buffer.
    - The `~` character was formerly used to toggle the case of the highlighted text. For me, this one was useful but not useful enough to warrant that particular keybind. In the future I would like to add a new keybind for case-toggle.
        - Now it is used to search for a file to open in the current buffer.

If you don't like these settings but still want to use this submodule, you can always override them in your own Nix configurations. Note that both the live grep and file search are specially configured to be Git-aware. If you press `?` or `~` from a Git repository, it will search files within the Git repository. If you press one of these keys from outside of a Git repository, it will search with the current working directory as the root.

#### hypr
When `pos.hypr.enable = true` is set, the main puddingOS "desktop environment" will be enabled. This includes a window management system with Hyprland, status bar, application launcher, screen locker, notification daemon, and tons of other desktop utilities.

Keep in mind that home-manager is only able to provide configuration for Hyprland; installations must be managed on the system side. This means that this module will have no effect without the corresponding NixOS submodule also being enabled.

#### qb
When `pos.qb.enable = true` is set, qutebrowser will be installed. It will also create a fish alias `qb` as a shorcut for launching `qutebrowser` directly. There are a few semi-significant changes from the default settings:

- The `u` and `Ctrl+r` keybindings now bind to the browser back and browser forward, reflecting traditional undo/redo behaviour in Vim.
    - You can still use the old bindings as well (`H` and `L`).
    - The `u` key was original bound to opening the last closed tab. This functionality has been moved to `U`, which was previously unbound.
- JavaScript clipboard access (copy on-click) is now allowed by default.
- The downloads directory is now `~/stuff/downloads`.

#### mangohud
When `pos.mangohud.enable = true` is set, MangoHud will be installed and enabled session wide for that user. This means it will be automatically enabled for all applicable programs, but it will be hidden by default. The mode cycle keybind has been replaced with a single on-off toggle with `F3`, which is meant to reflect the behaviour of the Minecraft debug menu which serves a similar purpose.
