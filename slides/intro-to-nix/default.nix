{ pkgs, lib, reveal-js, ... }:

import ../../lib/make-reveal-js.nix {
  inherit pkgs lib reveal-js;

  name = "intro-to-nix";
  version = "20230328.1";
  src = ./.;
  license = lib.licenses.cc-by-nc-sa-40;

  slideLevel = 2;
  katex = true;
  pandocVariables = {
    menu = true;
    theme = "black";
    width = 1366;
    height = 768;
  };
}
