# Seelies (WIP)

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
