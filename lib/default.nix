{ nixpkgs, ... }: rec {
  # Put all custom library functions under "seelies" namespace
  seelies =
    let
      lib = nixpkgs.lib // { inherit seelies; };
      concatAttrs = attrList: builtins.foldl' (x: y: x // y) { } attrList;
    in
    concatAttrs [
      (import ./reveal-js.nix)
      (import ./filesystem.nix { inherit lib; })
      (import ./site.nix)
      ({ inherit concatAttrs; })
    ];
}
