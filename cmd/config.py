#!/usr/bin/env python
from static import panic, prompt_yn, prompt_text, write_to_file, run_cmd

# Utilities for file management.
from os import path
from shutil import copy as cp
from pickle import load, dump

# Get system information for default config.
from socket import gethostname
from getpass import getuser


# Default values for the system configuration.
DEFAULT_CONFIG: dict = {
    "installed_modules": [],  # List of puddingOS modules to install upon rebuild.
    "user": getuser(),  # The primary admin user for puddingOS.
    "boot_device": "",  # Used for bios boot mode. Blank value indicates EFI boot.
    "import_from_local_clone": False,  # Clone/import puddingOS at an editable path.
    "hostname": gethostname(),  # System hostname.
}


def install_module(module_name: str):
    """Update the system configuration to import a particular module."""
    if not __check_module(module_name):
        return False
    config = __load_config()

    # Reconfigure existing module.
    if module_name in config["installed_modules"]:
        print("This module is already installed.")
        if prompt_yn("Do you want to reconfigure this module?"):
            new_config = __configure_module(module_name, config)
            if config == new_config:
                return False

        else:
            return False

    # Install new module.
    else:
        if prompt_yn("Do you want to install this module?"):
            print(f"Installing puddingOS module: {module_name}...")
            config["installed_modules"].append(module_name)
            config = __configure_module(module_name, config)
        else:
            return False

    # Apply changes.
    __apply_config(config)
    __save_config(config)
    return True


def remove_module(module_name: str):
    if not __check_module(module_name):
        return False
    config = __load_config()

    # Make sure the module is already installed first.
    if module_name not in config["installed_modules"]:
        print("Module is not installed.")
        return False

    # Prompt removal.
    if prompt_yn("Do you want to remove this module?"):
        print(f"Installing puddingOS module: {module_name}...")
        config["installed_modules"].remove(module_name)

    # Apply changes.
    __apply_config(config)
    __save_config(config)
    return True


def __check_module(module_name: str) -> bool:
    """Returns true if the module exists and prints relevant output."""
    # For now, only puddingOS core modules are supported.
    if not module_name in ["pos-system", "pos-home"]:
        print(f"No puddingOS module called '{module_name}'.")
        print("Package management with the pos command is not yet supported")
        return False

    print(f"puddingOS core module: {module_name}")
    return True


def __configure_module(module_name: str, config: dict):
    """Set up module-specific configurations."""
    if module_name == "pos-system":
        print(
            "\nBy default, puddingOS is pulled from the remote Git repository directly into the Nix store, which is readonly. Further configurations start at /etc/nixos/pos/configuration.nix, which should be used for personal customizations. If you want to modify puddingOS directly, it must be manually cloned to an accessible location and loaded by its local path. This is not recommended for most users."
        )

        # Check for existing clone.
        clone_path = f"/home/{config['user']}/.pos"
        config["import_from_local_clone"] = path.exists(f"{clone_path}/.git")
        if config["import_from_local_clone"]:
            print(f"\nA Git repository was found at {clone_path}.")
            config["import_from_local_clone"] = prompt_yn(
                "Do you want to try to import it?"
            )

        # TODO: Clone the repository automatically.
        if not config["import_from_local_clone"]:
            print(
                "\nNote that if you enable this, you will have to manually pull and merge from the remote repository in order to update puddingOS. This will apply to all core modules."
            )
            if prompt_yn("\nDo you want to import from a fresh local clone?", False):
                panic("Automatic cloning is not yet supported.")
            config["import_from_local_clone"] = False

        # Prompt for the device hostname.
        new_hostname = prompt_text(
            "Enter a hostname for this system.", config["hostname"]
        )
        if new_hostname != config["hostname"]:
            config["hostname"] = new_hostname
            run_cmd(f"sudo hostname {new_hostname}")

        # Detect EFI or BIOS boot.
        if path.exists("/sys/firmware/efi"):
            print("Detected EFI boot mode.")
            config["boot_device"] = ""
        else:
            print("Detected BIOS boot mode.")
            config["boot_device"] = prompt_text(
                "Enter boot device for GRUB [/dev/sda]: ", "/dev/sda"
            )
    else:
        print("Nothing to configure.")
    return config


def __load_config() -> dict:
    """Load  auto-configuration data. If it doesn't exist, prompt the user to set it up."""
    __initialize_system()

    # Load existing configuration data.
    with open("/etc/nixos/pos/.pos.pickle", "rb") as file:
        config = DEFAULT_CONFIG
        new_config = load(file)

        # Merge configs (necessary for when new config keys are added).
        for key in new_config.keys():
            config[key] = new_config[key]

    return config


def __save_config(config: dict):
    """Save the given dictionary to the Python configuration file."""
    with open("/etc/nixos/pos/.pos.pickle", "wb") as file:
        dump(config, file)


def __initialize_system():
    is_nixos = path.exists("/etc/NIXOS")
    if not is_nixos:
        panic("Auto-configuration on non-NixOS systems is not yet supported.")

    # Determine if the system is being auto-configured by puddingOS.
    is_autoconfigured = False
    if path.exists("/etc/nixos/pos/.last_generated_flake.nix") and path.exists(
        "/etc/nixos/flake.nix"
    ):
        with open("/etc/nixos/pos/.last_generated_flake.nix", "r") as file:
            last_generated_flake = file.read()
        with open("/etc/nixos/flake.nix", "r") as file:
            current_flake = file.read()

        # Disable auto-configuration if the user edits /etc/nixos/flake.nix manually.
        if last_generated_flake == current_flake:
            is_autoconfigured = True

    # Prompt the user to set up auto-configuration if it's not enabled.
    if is_autoconfigured:
        return

    print("""\
This system is not currently being auto-configured. If you enable auto-configuration, \
then:
- Your /etc/nixos/flake.nix will be managed (i.e. OVERWRITTEN) by puddingOS.
- Further configurations use /etc/nixos/pos/configuration.nix as the entry point.""")
    if prompt_yn("Do you want to set up auto-configuration?", False):
        # Initialize the extended configuration directory if needed.
        if not path.exists("/etc/nixos/pos"):
            run_cmd("sudo mkdir /etc/nixos/pos")
            run_cmd(f"sudo chown {getuser()} /etc/nixos/pos")
        if not path.exists("/etc/nixos/pos/configuration.nix"):
            default_user_config_text = """
    {...}: {
        # User-specific configuration for this machine.
        # This file is safe to edit and won't be overwritten by the setup script.
        # WiFi configuration (wpa_supplicant).
        networking.wireless = {
            enable = true;
            networks = {
                # Format: "SSID".psk = "password"
                # Example:
                #"EpicWifi".psk = "hunter2";
            };
        };
        
        # Toggle the SSH server for remote access.
        services.openssh.enable = true;
        home-manager.users.$ACTUAL_USER = {
            # Display configuration (Hyprland only)
            wayland.windowManager.hyprland.settings.monitor = [
                # Format: "input,resolution@refreshrate,XoffsetxYoffset,scale"
                # Examples:
                # "HDMI-A-1,1920x1080@60,0x0,1.00"
                # "DP-1,3440x1440@240,0x0,1.00"
                # "eDP-1,1920x1200@60,0x0,1.00"
            ];
        };
    }
    """
            write_to_file(
                default_user_config_text,
                "/etc/nixos/pos/configuration.nix",
                True,
            )

        # Create default configuration data as necessary.
        if not path.exists("/etc/nixos/flake.nix"):
            run_cmd("sudo touch /etc/nixos/flake.nix")
        cp("/etc/nixos/flake.nix", "/etc/nixos/pos/.last_generated_flake.nix")
        __save_config(DEFAULT_CONFIG)

        # Run through initialization.
        install_module("pos-system")
        install_module("pos-home")
        if path.exists("/etc/nixos/flake.lock"):
            run_cmd("sudo nix flake update --flake /etc/nixos")
        run_cmd(
            'env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch'
        )

    exit()


def __apply_config(config):
    """Update the Nix system configuration based on the Python configuration data."""
    new_config_text = __generate_config_text(config)
    write_to_file(new_config_text, "/etc/nixos/pos/.last_generated_flake.nix")
    write_to_file(new_config_text, "/etc/nixos/flake.nix", True)


def __generate_config_text(config):
    """Generate Nix configuration based on the Python configuration data."""
    config_text = """
{{
    # ===================================================================================
    # WARNING: This configuration was original generated by the puddingOS init script!
    # 
    # Rather than editing directly, it is recommended that you modify these settings with
    # the configuration tool by running "pos init" and use /etc/nixos/pos for further
    # Nix customizations.
    # 
    # If you choose to edit this file yourself, it can always be generated with pos init.
    # ===================================================================================

    description = \"puddingOS";

    inputs = {{
        pos-system.url = "{system_url}";
        nixpkgs.follows = "pos-system/nixpkgs";{home_inputs}
        pos-cmd.url = "{cmd_url}";
    }};

    outputs = {{
        pos-system,{home_output_header}
        pos-cmd,
        ...
    }}: {{
        nixosConfigurations.{hostname} = (pos-system.nixosConfigurations.makeSystem {{
            username = "{username}";
        }}).extendModules {{
            modules = [
                # Base configuration setup for the system module.
                {{
                    networking.hostName = "{hostname}";   
                    time.timeZone = "America/Chicago";
                    environment.systemPackages = [pos-cmd.packages.x86_64-linux.default];
                }}{boot_outputs}{home_outputs}

                ./hardware-configuration.nix # Auto-generated hardware settings.
                ./pos/configuration.nix # Additional Nix configuration.
            ];
        }};
    }};
}}""".format(
        system_url=f"path:/home/{config['user']}/.pos/system"
        if config["import_from_local_clone"]
        else "github:dr-pudding/pos/main?dir=system",
        hostname=config["hostname"],
        boot_outputs="""\n
                # Bootloader configuration setup for non-EFI booting.
                {{
                    boot.loader.grub.device = {boot_device};
                    boot.loader.grub.efiSupport = false; 
                }}""".format(boot_device=config["boot_device"])
        if len(config["boot_device"]) > 0
        else "",
        cmd_url=f"path:/home/{config['user']}/.pos/cmd"
        if config["import_from_local_clone"]
        else "github:dr-pudding/pos/main?dir=cmd",
        username=config["user"],
        home_inputs="""\n
        pos-home.url = "{home_url}";
        home-manager.follows = "pos-home/home-manager";
        """.format(
            home_url=f"path:/home/{config['user']}/.pos/home"
            if config["import_from_local_clone"]
            else "github:dr-pudding/pos/main?dir=home",
        )
        if "pos-home" in config["installed_modules"]
        else "",
        home_outputs="""\n
                # User-level configuration setup for the home module.
                home-manager.nixosModules.home-manager
                {{
                    home-manager = {{
                        useGlobalPkgs = true;
                        useUserPackages = true;
                        users.{username}.imports = pos-home.homeModules.default {{
                            username = "{username}";
                        }};
                    }};
                }}""".format(username=config["user"])
        if "pos-home" in config["installed_modules"]
        else "",
        home_output_header="""
        pos-home,
        home-manager,"""
        if "pos-home" in config["installed_modules"]
        else "",
    )

    return config_text
