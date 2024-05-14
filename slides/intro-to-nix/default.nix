{ pkgs, lib, reveal-js, ... }:

lib.seelies.mkRevealJs {
  inherit pkgs lib reveal-js;

  name = "intro-to-nix";
  title = "Introducing Nix: declarative builds and deployments";
  version = "20230328.2";
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
