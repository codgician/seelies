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

      buildInputs = with pkgs; [ pandoc graphviz ];
      installPhase =
        let
          luaFiltersPath = "${pkgs.pandoc-lua-filters}/share/pandoc/filters";
          pandocArgs = builtins.concatStringsSep " " ([
            # Use reveal.js from input
            "--variable"
            "revealjs-url=./assets/reveal.js"

            # Use katex from nixpkgs
            (lib.optionals katex "--katex=./assets/katex-dist/")

            # Code highlight theme
            "--highlight-style=zenburn"

            # Set slide level
            "--slide-level ${builtins.toString slideLevel}"

            # Add Lua filters
            "--lua-filter"
            "${luaFiltersPath}/diagram-generator.lua"
          ] ++ builtins.attrValues (builtins.mapAttrs (k: v: "-V ${k}=${builtins.toString v}") pandocVariables));
        in
        ''
          mkdir -p $out/assets
          ln -s ${reveal-js} $out/assets/reveal.js
          ln -s ${pkgs.nodePackages.katex}/lib/node_modules/katex/dist $out/assets/katex-dist
          ${pkgs.pandoc}/bin/pandoc --embed-resources -s -t revealjs -o $out/index.html slides.md ${pandocArgs}
        '' + builtins.concatStringsSep "\n" (builtins.map (dir: "ln -s ${dir} $out/${builtins.baseNameOf dir}") additonalFolders);

      meta = {
        inherit license;
        description = title;
        longDescription = description;
      };
    };
}
