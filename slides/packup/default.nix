{ pkgs, lib, ... }:

lib.seelies.mkRevealJs {
  inherit pkgs lib;

  name = "packup";
  title = "Package Upgradability: the algorithm behind packup";
  version = "2022.09.23-1";
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
