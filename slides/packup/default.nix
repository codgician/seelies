{ pkgs, lib, reveal-js }:

lib.seelie.mkRevealJs {
  inherit pkgs lib reveal-js;

  name = "packup";
  version = "20220923.1";
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
