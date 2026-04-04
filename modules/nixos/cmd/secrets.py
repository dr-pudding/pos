import click
import secrets as secrets_module

from os import environ, path, chdir, makedirs, listdir, remove as os_remove
from static import run_cmd

SECRETS_DIR = "/etc/nixos/pos/secrets"


def get_user_keys():
    """Get public keys from the SSH agent."""
    result = run_cmd("ssh-add -L", silent=True, capture_output=True, text=True)
    if result.returncode != 0 or not result.stdout.strip():
        click.echo(
            "Error: No keys found in SSH agent.\n\n"
            "Ensure that your SSH agent is running and has a public key added to it.",
            err=True,
        )
        raise SystemExit(1)
    return result.stdout.strip().splitlines()


def get_host_key():
    """Get the machine's SSH host public key."""
    try:
        with open("/etc/ssh/ssh_host_ed25519_key.pub") as f:
            return f.read().strip()
    except FileNotFoundError:
        click.echo(
            "Error: Host key not found. Is the SSH server enabled?",
            err=True,
        )
        raise SystemExit(1)


def write_temp_secrets_nix(secrets_dir: str, name: str, keys: list):
    """Write a temporary secrets.nix for agenix to consume."""
    keys_nix = "\n".join(f'    "{k}"' for k in keys)
    contents = f'{{\n  "{name}.age".publicKeys = [\n{keys_nix}\n  ];\n}}\n'
    secret_nix_path = path.join(secrets_dir, "secrets.nix")
    with open(secret_nix_path, "w") as f:
        f.write(contents)
    return secret_nix_path


def print_secret_info(name: str, secrets_dir: str):
    """Print the NixOS config snippet for a secret."""
    age_file = path.join(secrets_dir, f"{name}.age")
    click.echo(
        f"Add the following anywhere in your NixOS configuration.\n\n"
        f"age.secrets.{name} = {{\n"
        f"    file = {age_file};\n"
        f'    owner = "<service-user>";\n'
        f"}};\n\n"
        f"Set owner to the user that needs to read this secret.\n"
    )


@click.group()
@click.option(
    "--dir",
    default=SECRETS_DIR,
    show_default=True,
    help="Override the default directory for storing and reading secrets.",
)
@click.pass_context
def secrets(ctx, dir: str):
    """Manage secrets with agenix."""
    ctx.ensure_object(dict)
    ctx.obj["dir"] = dir


@secrets.command()
@click.argument("name")
@click.pass_context
def add(ctx, name: str):
    """Create a new secret."""
    secrets_dir = ctx.obj["dir"]
    if not path.exists(secrets_dir):
        run_cmd(f"sudo mkdir -p {secrets_dir}")
    age_file = path.join(secrets_dir, f"{name}.age")

    # Ensure the file doesn't exist already.
    if path.exists(age_file):
        click.echo(f"Error: File already exists.", err=True)
        raise SystemExit(1)

    # Read SSH keys.
    user_keys = get_user_keys()
    host_key = get_host_key()
    all_keys = user_keys + [host_key]

    # Create the temporary secrets.nix data.
    tmp_dir = path.join(environ.get("XDG_RUNTIME_DIR", "/tmp"), "pos-secrets-tmp")
    makedirs(tmp_dir, exist_ok=True)
    secrets_nix_path = write_temp_secrets_nix(tmp_dir, name, all_keys)

    # Generate the secret data.
    # token_urlsafe(24) produces exactly 32 URL-safe characters from 24 random bytes.
    encoded = secrets_module.token_urlsafe(24)

    # Create the secret with agenix.
    chdir(tmp_dir)
    proc = run_cmd(
        f"agenix -e {name}.age",
        input=encoded,
        text=True,
    )

    # Handle errors on the agenix end.
    if proc.returncode != 0:
        click.echo("Error: agenix failed.", err=True)
        raise SystemExit(1)

    # Move the secret file to the correct directory.
    tmp_age = path.join(tmp_dir, f"{name}.age")
    run_cmd(f"sudo mv {tmp_age} {age_file}")

    # Handle output.
    os_remove(secrets_nix_path)
    print_secret_info(name, secrets_dir)


@secrets.command()
@click.argument("name")
@click.pass_context
def remove(ctx, name: str):
    """Delete an existing secret."""
    secrets_dir = ctx.obj["dir"]
    age_file = path.join(secrets_dir, f"{name}.age")

    # Ensure file exists.
    if not path.exists(age_file):
        click.echo(f"Error: File not found.", err=True)
        raise SystemExit(1)

    # Prevent accidental delete.
    click.confirm(
        f"Are you sure you want to delete {name}.age? This cannot be undone.",
        abort=True,
    )
    run_cmd(f"sudo rm {age_file}")


@secrets.command("list")
@click.argument("name", required=False)
@click.pass_context
def list_secrets(ctx, name: str):
    """List all secrets or show info for a particular secret."""
    secrets_dir = ctx.obj["dir"]

    if name:  # Name is given, show information for it.
        age_file = path.join(secrets_dir, f"{name}.age")

        # Ensure the given name exists.
        if not path.exists(age_file):
            click.echo(
                f"Error: File not found. ",
                err=True,
            )
            raise SystemExit(1)

        print_secret_info(name, secrets_dir)
    else:  # No name, list all secrets.
        try:
            # Strip the .age extension to get the secret names.
            files = [f[:-4] for f in listdir(secrets_dir) if f.endswith(".age")]

        # The secrets directory hasn't been created, so there are no secrets.
        except FileNotFoundError:
            click.echo("No secrets found.")
            return

        # The directory exists but contains no files, so there are no secrets.
        if not files:
            click.echo("No secrets found.")
            return

        # Handle output.
        out = ""
        for secret_name in sorted(files):
            out += secret_name
            out += " "
        click.echo(f"{out[:-1]}")
