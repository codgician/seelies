{ lib, ... }: {
  mkSite =
    { pkgs
    , lib
    , name
    , version
    , src
    , license ? lib.licenses.cc-by-nc-sa-40
    , slidePkgs ? [ ]
    }:

    pkgs.stdenv.mkDerivation rec {
      pname = name;
      inherit version src;

      installPhase = builtins.concatStringsSep "\n" (builtins.map
        (p: ''
          mkdir -p $out/${p.pname}
          ln -s ${p}/* $out/${p.pname}
        '')
        slidePkgs);

      meta = { inherit license; };
    };
}
