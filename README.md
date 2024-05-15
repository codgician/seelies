# Seelies (WIP)

[![build](https://github.com/codgician/seelies/actions/workflows/build.yml/badge.svg)](https://github.com/codgician/seelies/actions/workflows/build.yml)
[![pages](https://github.com/codgician/seelies/actions/workflows/pages.yml/badge.svg)](https://github.com/codgician/seelies/actions/workflows/pages.yml)

This repository contains slides I've made.

## Quick start

To build all slides:

```bash
nix build
```

To host all slides with a static http server under localhost:

```bash
nix run
```

To build a individual slide only (e.g. `packup`):

```bash
nix build .#packup
```

To start development shell, run:

```bash
nix develop -c $SHELL
```

To debug flake output using a REPL, run:

```bash
nix run .#repl
```

## Details

* Slides are written with [R Markdown](https://rmarkdown.rstudio.com) in file named `slides.Rmd` under `/slides` folder.
* During build, `knitr` is first called to convert `*.Rmd` into `*.md`. Then `pandoc` is called to convert `*.md` into `*.html`.