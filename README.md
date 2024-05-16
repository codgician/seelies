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

- Slides are written with [R Markdown](https://rmarkdown.rstudio.com) in file named `slides.Rmd` under `/slides` folder.
- During build:
  *  Call `rmarkdown::render()` to render `slides.Rmd` with output type being `html_document`.
  *  However, we only take the intermediate `slides.md` and discard the resulting `slides.html`.
  *  `slides.md` is then rendered to `index.html` using pandoc with revealjs template with custom arguments.
  *  This resulted in highly limited R functionality.
