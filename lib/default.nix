{ nixpkgs, ... }:
let
  lib = nixpkgs.lib;
  concatAttrs = attrList: builtins.foldl' (x: y: x // y) { } attrList;
in
rec {
  # Put all custom library functions under "seelie" namespace
  seelie = concatAttrs [
    (import ./revealjs.nix)
  ];
}
