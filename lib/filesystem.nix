{ lib, ... }: {
  # List all folder names under specified path
  getFolderNames = path:
    let
      dirContent = builtins.readDir path;
    in
    builtins.filter (name: dirContent.${name} == "directory") (builtins.attrNames dirContent);
}
