{ pkgs, lib, reveal-js }:

lib.seelies.mkRevealJs {
  inherit pkgs lib reveal-js;

  name = "permutation-group";
  version = "2020.04.11";
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

  additonalFolders = [ ./images ];
}
