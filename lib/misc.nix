{ lib, ... }: {
  # Concat attributes
  concatAttrs = attrList: builtins.foldl' (x: y: x // y) { } attrList;
}
