{ pkgs, lib, reveal-js, ... }:

lib.seelies.mkRevealJs {
  inherit pkgs lib reveal-js;

  name = "nix-intro";
  title = "Introducing Nix: declarative builds and deployments";
  version = "2024.05.20-0";
  src = ./.;
  license = lib.licenses.cc-by-nc-sa-40;

  slideLevel = 2;
  katex = true;
  highlightStyle = "pygments";
  pandocVariables = {
    menu = true;
    theme = "white";
    width = 1366;
    height = 768;
  };

  additonalFolders = [ ./images ];
}
