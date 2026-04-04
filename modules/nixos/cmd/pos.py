import click
from secrets import secrets

from os import system as os_system


@click.group(invoke_without_command=True)
@click.pass_context
def cmd(ctx):
    """Manage a puddingOS system."""
    if ctx.invoked_subcommand is None:
        click.echo(ctx.get_help())


cmd.add_command(secrets)


@cmd.command()
@click.option(
    "--offline",
    help="Disable network features to ensure successful offline build.",
    is_flag=True,
)
def rebuild(offline: bool = False):
    """Rebuild the system."""
    if offline:
        run_cmd("sudo nixos-rebuild switch --offline")
    else:
        run_cmd("sudo nixos-rebuild switch")


@cmd.command()
def update():
    """Update flake inputs."""
    run_cmd("sudo nix flake update --flake /etc/nixos")


@cmd.command()
def upgrade():
    """Upgrade the system (update + rebuild)."""
    update.invoke(ctx=click.Context(update))
    rebuild.invoke(ctx=click.Context(rebuild))


def run_cmd(cmd):
    """Run a command on the Linux terminal."""
    print(f"> {cmd}")
    os_system(cmd)


if __name__ == "__main__":
    cmd()
