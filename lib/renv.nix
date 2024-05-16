{
  # Create R environment
  mkREnv = pkgs: pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      rmarkdown
      diagram
      extrafont
      katex
      DiagrammeR
    ];
  };
}
