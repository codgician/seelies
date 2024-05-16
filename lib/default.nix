{ nixpkgs, ... }:
let
  lib = nixpkgs.lib;
  concatAttrs = attrList: builtins.foldl' (x: y: x // y) { } attrList;
in
rec {
  # Put all custom library functions under "seelie" namespace
  seelies = concatAttrs [
    (import ./reveal-js.nix)
    (import ./filesystem.nix { inherit lib; })
    (import ./misc.nix { inherit lib; })
    (import ./site.nix)
  ];
}
