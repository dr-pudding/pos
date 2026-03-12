# This is the development shell for puddingOS.
# It's mostly used to provide a Python environment for the custom CLI utilities.
{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
    packages = with pkgs; [
        python3
        python3Packages.click
    ];
}
