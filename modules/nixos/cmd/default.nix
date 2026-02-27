{pkgs ? import <nixpkgs> {}}: let
    pythonWithPackages = pkgs.python3.withPackages (ps: [ps.click]);
in
    pkgs.stdenv.mkDerivation {
        name = "pos";
        src = ./.;
        buildInputs = [pythonWithPackages];
        nativeBuildInputs = [pkgs.makeWrapper];
        installPhase = ''
            # Copy all Python modules.
            mkdir -p $out/bin $out/lib/pos
            cp *.py $out/lib/pos/

            # Create wrapper for the pos command.
            cat > $out/bin/pos << EOF
            #!${pythonWithPackages}/bin/python3
            import sys
            sys.path.insert(0, "$out/lib/pos")
            exec(open("$out/lib/pos/pos_cmd.py").read())
            EOF
            chmod +x $out/bin/pos
        '';
    }
