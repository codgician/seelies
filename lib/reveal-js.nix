{
  mkRevealJs =
    { pkgs
    , lib
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

      buildInputs = with pkgs; [ pandoc ];
      installPhase =
        let
          renv = lib.seelies.mkREnv pkgs;
          pandocArgs = [
            # Use reveal.js from input
            "--variable"
            "revealjs-url=./assets/reveal.js"

            # Use katex from nixpkgs
            (lib.optionals katex "--katex=./assets/katex-dist/")

            # Code highlight theme
            "--highlight-style=zenburn"

            # Set slide levelnix
            "--slide-level ${builtins.toString slideLevel}"

            # Add RMarkdown lua filters
            # "--lua-filter" 
            # "${pkgs.rPackages.rmarkdown}/library/rmarkdown/rmarkdown/lua/pagebreak.lua"
            # "--lua-filter"
            # "${pkgs.rPackages.rmarkdown}/library/rmarkdown/rmarkdown/lua/latex-div.lua"

          ] ++ builtins.concatLists (builtins.attrValues (lib.mapAttrs (k: v: [ "--variable" "${k}=${builtins.toString v}" ]) pandocVariables));
        in
        ''
          mkdir -p $out/assets
          ln -s ${pkgs.nodePackages.katex}/lib/node_modules/katex/dist $out/assets/katex-dist
          ln -s ${pkgs.seelies.reveal-js} $out/assets/reveal.js

          ${renv}/bin/Rscript -e 'knitr::knit(
            input = "slides.Rmd",
            output = "slides.md"
          )

          cp ./slides.md $out/slides.md
          pandoc -s slides.md -o $out/index.html --to=revealjs ${builtins.concatStringsSep " " pandocArgs}
        '' + builtins.concatStringsSep "\n" (builtins.map (folder: "ln -s ${folder} $out/${builtins.baseNameOf folder}") additonalFolders);

      meta = {
        inherit license;
        description = title;
        longDescription = description;
      };
    };
}
