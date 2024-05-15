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

      buildInputs = with pkgs; [ pandoc which ];
      installPhase =
        let
          renv = pkgs.rWrapper.override { 
            packages = with pkgs.rPackages; [ rmarkdown revealjs ];
          };
          rmdPath = "${src}/slides.Rmd";
          pandocArgs = [

            # Use katex from nixpkgs
            (lib.optionals katex "--katex=./assets/katex-dist/")

          ] ++ builtins.attrValues (builtins.mapAttrs (k: v: "-V ${k}=${builtins.toString v}") pandocVariables);
          pandocArgsInR = builtins.concatStringsSep ", " (builtins.map (x: ''"${x}"'') pandocArgs);
        in
        ''
          mkdir -p $out/assets
          ln -s ${reveal-js} $out/assets/reveal.js
          ln -s ${pkgs.nodePackages.katex}/lib/node_modules/katex/dist $out/assets/katex-dist
          ${renv}/bin/Rscript -e 'rmarkdown::render(
            input = "slides.Rmd", 
            output_format = "revealjs::revealjs_presentation", 
            output_file = "index.html",
            output_options = list(mathjax = NULL, pandoc_args = c(${pandocArgsInR}))
          )'
          mv ./index.html $out/index.html
        '' + builtins.concatStringsSep "\n" (builtins.map (folder: "ln -s ${folder} $out/${builtins.baseNameOf folder}") additonalFolders);

      meta = {
        inherit license;
        description = title;
        longDescription = description;
      };
    };
}
