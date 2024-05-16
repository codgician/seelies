{
  description = "A collection of slides made by codgician.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs @ { self
    , nixpkgs
    , flake-utils
    , ...
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      lib = nixpkgs.lib // (import ./lib { inherit nixpkgs; });
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      slides = lib.seelies.getFolderNames ./slides;
      mkSlidePkg = name: import ./slides/${name} { inherit lib pkgs; };
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
            confnix=$(mktemp)
            echo "builtins.getFlake (toString $(git rev-parse --show-toplevel))" > $confnix
            trap "rm $confnix" EXIT
            nix repl $confnix
          '';
        };
      };

      # Development shell
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          pandoc
          httplz
          (rWrapper.override { packages = with rPackages; [ rmarkdown ]; })
          texlive.combined.scheme-full
        ];
      };

      # Formatter: `nix fmt`
      formatter = pkgs.nixpkgs-fmt;
    });
}
