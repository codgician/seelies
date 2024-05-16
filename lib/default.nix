{ nixpkgs, ... }: rec {
  # Put all custom library functions under "seelie" namespace
  seelies =
    let
      lib = nixpkgs.lib // { inherit seelies; };
      concatAttrs = attrList: builtins.foldl' (x: y: x // y) { } attrList;
    in
    concatAttrs [
      (import ./reveal-js.nix)
      (import ./filesystem.nix { inherit lib; })
      (import ./misc.nix { inherit lib; })
      (import ./site.nix)
    ];
}
