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

    let
      inHeader = pkgs.writeTextFile {
        name = "katex-header.html";
        text = lib.optionals katex ''
          <script defer src="./assets/katex-dist/katex.min.js" />
          <script defer src="./assets/katex-dist/contrib/auto-render.min.js" />
          <link rel="stylesheet" href="./assets/katex-dist/katex.min.css" />
          <script>
            document.addEventListener("DOMContentLoaded", function() {
              renderMathInElement(document.body, {
                delimiters: [
                  {left: '$$', right: '$$', display: true},
                  {left: '$', right: '$', display: false},
                  {left: '\\(', right: '\\)', display: false},
                  {left: '\\[', right: '\\]', display: true}
                ],
                throwOnError : false
              });
           });
          </script>
        '';
      };
    in
    pkgs.stdenv.mkDerivation rec {
      pname = name;
      inherit version src;

      buildInputs = with pkgs; [ pandoc ];
      installPhase =
        let
          renv = lib.seelies.mkREnv pkgs;
        in
        ''
          mkdir -p $out/assets
          ln -s ${pkgs.nodePackages.katex}/lib/node_modules/katex/dist $out/assets/katex-dist
          ${renv}/bin/Rscript -e 'rmarkdown::render(
            input = "slides.Rmd", 
            output_format = "revealjs::revealjs_presentation", 
            output_file = "index.html",
            output_options = list(
              mathjax = NULL, 
              includes = list(in_header = "${inHeader}")
            )
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
