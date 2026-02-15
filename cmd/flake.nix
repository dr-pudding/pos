{
    outputs = {nixpkgs, ...}: let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        pythonWithPackages = pkgs.python3.withPackages (ps: [ps.click]);
    in {
        packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
            name = "pos";
            src = ./.;
            buildInputs = [pythonWithPackages];
            installPhase = ''
                mkdir -p $out/bin $out/lib/pos

                # Copy all Python modules.
                cp *.py $out/lib/pos/

                # Create wrapper script.
                cat > $out/bin/pos << EOF
                #!${pythonWithPackages}/bin/python3
                import sys
                sys.path.insert(0, "$out/lib/pos")
                exec(open("$out/lib/pos/pos_cmd.py").read())
                EOF
                chmod +x $out/bin/pos
            '';
        };
    };
}
