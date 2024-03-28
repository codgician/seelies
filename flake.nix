{
  description = "A collection of slides made by codgician.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";

    reveal-js = {
      url = "github:hakimel/reveal.js";
      flake = false;
    };
  };

  outputs =
    inputs @ { self
    , nixpkgs
    , flake-utils
    , reveal-js
    , ...
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages = {
        intro-to-nix = import ./slides/intro-to-nix { inherit lib pkgs reveal-js; };
        packup = import ./slides/packup { inherit lib pkgs reveal-js; };
      };

      apps = {
        repl = inputs.flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "repl" ''
            confnix=$(mktemp)
            echo "builtins.getFlake (toString $(git rev-parse --show-toplevel))" > $confnix
            trap "rm $confnix" EXIT
            nix repl $confnix
          '';
        };
      };

      # Development shells
      devShells = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pandoc
            httplz
          ];
        };
      };

      # Formatter: `nix fmt`
      formatter = pkgs.nixpkgs-fmt;
    });
}
