{
  # Create R environment
  mkREnv = pkgs: pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      rmarkdown
      extrafont
      katex
      DiagrammeR
      DiagrammeRsvg
      magrittr
      htmltools
    ];
  };
}
