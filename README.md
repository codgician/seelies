# Seelies (WIP)

[![build](https://github.com/codgician/seelies/actions/workflows/build.yml/badge.svg)](https://github.com/codgician/seelies/actions/workflows/build.yml)
[![pages](https://github.com/codgician/seelies/actions/workflows/pages.yml/badge.svg)](https://github.com/codgician/seelies/actions/workflows/pages.yml)

This repository contains slides I've made.

## Quick start

Taking slide `intro-to-nix` as an example. 

To build the slide into static webpages, run:

```bash
nix build .#intro-to-nix
```

To server the slide at `http://localhost:8000`, run:

```bash
nix run .#intro-to-nix
```
