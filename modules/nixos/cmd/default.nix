{pkgs, ...}: let
    agenix = builtins.fetchGit {
        url = "https://github.com/ryantm/agenix.git";
        rev = "96e078c646b711aee04b82ba01aefbff87004ded";
    };

    python = pkgs.python3.withPackages (ps: [ps.click]);
    posPkg = pkgs.stdenv.mkDerivation {
        name = "pos";
        src = ./.;
        buildInputs = [python];
        installPhase = ''
            mkdir -p $out/lib/pos $out/bin
            cp *.py $out/lib/pos/
            cat > $out/bin/pos <<EOF
            #!${python}/bin/python3
            import sys
            sys.path.insert(0, "$out/lib/pos")
            from pos import cmd
            cmd()
            EOF
            chmod +x $out/bin/pos
        '';
    };
in {
    environment.systemPackages = [
        posPkg
        (pkgs.callPackage "${agenix}/pkgs/agenix.nix" {})
        pkgs.openssh
    ];
}
