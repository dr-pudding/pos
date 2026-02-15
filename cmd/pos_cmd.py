#!/usr/bin/env python
import click

from static import run_cmd, abort
from config import install_module, remove_module


@click.group(invoke_without_command=True)
@click.pass_context
def cmd(ctx):
    """puddingOS system management"""
    if ctx.invoked_subcommand is None:
        click.echo(ctx.get_help())


# ================================
# System version control/rebuilding.
# ================================
@cmd.command()
def rebuild():
    """Rebuild the system."""
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


# ================================
# Modules and package management.
# ================================
@cmd.command()
@click.argument("name")
@click.option(
    "--no-rebuild",
    help="Skip automatic system rebuild after installation.",
    is_flag=True,
)
def install(name: str, no_rebuild: bool = False):
    """Install a package or activate a puddingOS module.

    NAME can be puddingOS module or a Nix package.

    Available modules: pos-system, pos-home
    """

    if install_module(name):
        update.invoke(ctx=click.Context(update))

        if not no_rebuild:
            rebuild.invoke(ctx=click.Context(rebuild))
    else:
        abort()


@cmd.command()
@click.argument("name")
@click.option(
    "--no-rebuild",
    help="Skip automatic system rebuild after removal.",
    is_flag=True,
)
def remove(name: str, no_rebuild: bool = False):
    """Remove a package or deactivate a puddingOS module.

    NAME can be puddingOS module or a Nix package.
    """

    if remove_module(name):
        update.invoke(ctx=click.Context(update))

        if not no_rebuild:
            rebuild.invoke(ctx=click.Context(rebuild))
    else:
        abort()


if __name__ == "__main__":
    cmd()
