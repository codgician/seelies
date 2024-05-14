{
  mkSite =
    { pkgs
    , lib
    , name
    , title ? "Index"
    , description ? null
    , version
    , src
    , license ? lib.licenses.cc-by-nc-sa-40
    , slidePkgs ? [ ]
    }:

    let
      indexMd = pkgs.writeTextFile {
        name = "index.md";
        text = builtins.concatStringsSep "\n" ([ "${description}\n" ] ++ (builtins.map (p: "- [${p.meta.description}](${p.pname})") slidePkgs));
      };
    in
    pkgs.stdenv.mkDerivation rec {
      pname = name;
      inherit version src;

      installPhase = builtins.concatStringsSep "\n" (
        [
          "mkdir -p $out"
          "${pkgs.pandoc}/bin/pandoc -s -f gfm -o $out/index.html ${indexMd} --metadata title='${title}'"
        ]
        ++ (builtins.map (p: "mkdir -p $out/${p.pname} \n ln -s ${p}/* $out/${p.pname}") slidePkgs)
      );

      meta = {
        inherit license;
        description = name;
        longDescription = description;
      };
    };
}
