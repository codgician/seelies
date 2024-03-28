{ pkgs
, lib
, reveal-js
, name
, version
, src
, license ? lib.licenses.cc-by-nc-sa-40
, slideLevel ? 2
, katex ? false
, pandocVariables ? { }
}:

pkgs.stdenv.mkDerivation rec {
  pname = name;
  inherit version src;

  installPhase =
    let
      mdPath = "${src}/slides.md";
      args = builtins.concatStringsSep " " ([
        "--slide-level ${builtins.toString slideLevel}"
        (lib.optionals katex "--katex")
      ] ++ builtins.attrValues (builtins.mapAttrs (k: v: "-V ${k}=${builtins.toString v}") pandocVariables));
    in
    ''
      mkdir $out
      ln -s ${reveal-js} $out/reveal.js
      ${pkgs.pandoc}/bin/pandoc -s -t revealjs -o $out/index.html ${mdPath} ${args}
    '';

  meta = {
    inherit license;
  };
}
