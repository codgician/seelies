# Seelies (WIP)

[![build](https://github.com/codgician/seelies/actions/workflows/build.yml/badge.svg)](https://github.com/codgician/seelies/actions/workflows/build.yml)
[![pages](https://github.com/codgician/seelies/actions/workflows/pages.yml/badge.svg)](https://github.com/codgician/seelies/actions/workflows/pages.yml)
![Man hours](https://img.shields.io/endpoint?url=https%3A%2F%2Fmanhours.aiursoft.cn%2Fr%2Fgithub.com%2Fcodgician%2Fseelies.json)

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
