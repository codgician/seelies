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
      lib = nixpkgs.lib // (import ./lib { inherit nixpkgs; });
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      slides = lib.seelies.getFolderNames ./slides;
      mkSlidePkg = name: import ./slides/${name} { inherit lib pkgs reveal-js; };
      mkSlideApp = name: inputs.flake-utils.lib.mkApp {
        drv = pkgs.writeShellScriptBin name ''
          echo "Serving slides at: http://localhost:8000"
          ${pkgs.httplz}/bin/httplz -p 8000 -d '${mkSlidePkg name}'
        '';
      };
    in
    rec {
      packages = builtins.listToAttrs (builtins.map (name: { inherit name; value = mkSlidePkg name; }) slides);
      apps = (builtins.listToAttrs (builtins.map (name: { inherit name; value = mkSlideApp name; }) slides)) // {
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
