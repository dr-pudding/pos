# This is the development shell for puddingOS.
{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
    packages = with pkgs; [
        # Python environment for the custom CLI utilities.
        python3
        python3Packages.click

        # For generating documentation.
        mdbook
    ];
}
