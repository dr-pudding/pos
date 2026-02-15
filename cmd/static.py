from os import system as os_system


def run_cmd(cmd):
    """Run a command on the Linux terminal."""
    print(f"> {cmd}")
    os_system(cmd)


def prompt_yn(msg, default_yes=True):
    """Prompt the user for a boolean response."""
    if default_yes:
        print(f"{msg} [Y/n] ", end="")
    else:
        print(f"{msg} [y/N] ", end="")

    ipt = input()

    if ipt.lower().startswith("y"):
        return True
    elif ipt.lower().startswith("n"):
        return False
    elif ipt == "":
        return default_yes
    else:
        return False


def prompt_text(msg, default):
    """Prompt the user for a string response."""
    print(f"{msg} [{default}] ", end="")

    ipt = input()

    if ipt == "":
        return default
    else:
        return ipt


def write_to_file(text: str, file: str, use_sudo=False):
    """Store the given text in the given file."""

    if use_sudo:
        escaped = text.replace("'", "'\"'\"'")
        os_system(f"sudo sh -c 'cat > {file} << \"EOF\"\n{escaped}\nEOF'")
    else:
        os_system(f"echo '{text}' > {file}")


def panic(msg):
    """Exit immediately with an error message from click."""
    print(msg)
    abort()


def abort():
    """Exit immediately with indication of failure/cancellation."""
    print("Abort.")
    exit()
