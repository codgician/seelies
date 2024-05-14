{
  mkRevealJs =
    { pkgs
    , lib
    , reveal-js
    , name
    , title ? name
    , description ? null
    , version
    , src
    , license ? lib.licenses.cc-by-nc-sa-40
    , slideLevel ? 2
    , katex ? false
    , pandocVariables ? { }
    , additonalFolders ? [ ]
    }:

    pkgs.stdenv.mkDerivation rec {
      pname = name;
      inherit version src;

      installPhase =
        let
          mdPath = "${src}/slides.md";
          args = builtins.concatStringsSep " " ([
            # Use reveal.js from input
            "-V revealjs-url=./assets/reveal.js"

            # Use katex from nixpkgs
            (lib.optionals katex "--katex=./assets/katex-dist/")

            "--slide-level ${builtins.toString slideLevel}"
          ] ++ builtins.attrValues (builtins.mapAttrs (k: v: "-V ${k}=${builtins.toString v}") pandocVariables));
        in
        ''
          mkdir -p $out/assets
          ln -s ${reveal-js} $out/assets/reveal.js
          ln -s ${pkgs.nodePackages.katex}/lib/node_modules/katex/dist $out/assets/katex-dist
          ${pkgs.pandoc}/bin/pandoc -s -t revealjs -o $out/index.html ${mdPath} ${args}
        '' + builtins.concatStringsSep "\n" (builtins.map (folder: "ln -s ${folder} $out/${builtins.baseNameOf folder}") additonalFolders);

      meta = {
        inherit license;
        description = title;
        longDescription = description;
      };
    };
}
