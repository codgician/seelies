{
  description = "A collection of slides made by codgician.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
      mkSlideApp = slidePkg: inputs.flake-utils.lib.mkApp {
        drv = pkgs.writeShellScriptBin slidePkg.pname ''
          echo "Serving slides at: http://localhost:8000"
          ${pkgs.httplz}/bin/httplz -p 8000 -d '${slidePkg}' --quiet
        '';
      };
      slidePkgs = builtins.map mkSlidePkg slides;
    in
    rec {
      packages = (builtins.listToAttrs (builtins.map (p: { name = p.pname; value = p; }) slidePkgs)) // {
        default = lib.seelies.mkSite {
          inherit pkgs lib slidePkgs;
          name = "seelies";
          title = "Seelies";
          description = "A collection of slides made by [codgician](https://github.com/codgician).";
          version = "rolling";
          src = ./.;
          license = lib.licenses.cc-by-nc-sa-40;
        };
      };

      apps = (builtins.mapAttrs (k: v: mkSlideApp v) packages) // {
        repl = inputs.flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "repl" ''
            nix repl --expr "builtins.getFlake (toString $(${pkgs.git}/bin/git rev-parse --show-toplevel))"
          '';
        };
      };

      # Development shells
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          pandoc
          httplz
        ];
      };

      # Formatter: `nix fmt`
      formatter = pkgs.nixpkgs-fmt;
    });
}
