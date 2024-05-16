{ pkgs, lib, ... }:

lib.seelies.mkRevealJs {
  inherit pkgs lib;

  name = "nix-intro";
  title = "Introducing Nix: declarative builds and deployments";
  version = "2024.05.15-1";
  src = ./.;
  license = lib.licenses.cc-by-nc-sa-40;
  katex = true;
  additonalFolders = [ ./images ];
}
