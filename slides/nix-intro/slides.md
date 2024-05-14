---
author: [ codgician ]
title: 'Introducing Nix'
subtitle: Declarative builds and deployments
date: 2024.05.20
---

# Problem

- Software should be reproducible when copied among machines.
- Challenges: 
  * Most software today is not self-contained.
  * As they scale, deployment process becomes increasingly complex.
- We deal with these everyday at Deployment Team 🤪. 

## Environment issues

- Software today is almost **never self-contained**.
- Dependencies, both build time and run time, needs to be **compatible**. 
- Components need to be able to **find** dependencies. 
- Components may depend on **non-software artifacts** (e.g. databases).

::: { .notes }

- Dependencies: both build time and run time. Especially in OSS world, hard to know which source is the component built from.
- Compatibility: Even for non ABI breaking changes, implementation may change and cause side-effects.
- Needs to be able to find them (e.g. dynmaic linker search path).
- Non-software artifacts, e.g. database, user configurations.

:::

## Manageability issues

- **Uninstall / Upgrade**: should not induce failures to another part of the system (e.g. *[DLL hell](https://en.wikipedia.org/wiki/DLL_Hell)*).
- **Administrator queries**: file ownership? disk space consumption? source?
- **Incident mitigation**: able to undo / rollback effects of upgrades.
- **Variability**: build / deployment configurations may differ.
- **Maintenance**: may have different policies for keeping software up-to-date.
- ... and they scale for a **huge** fleet of machines with **different SKUs**.

::: { .notes }

- **Uninstall**: also should be as clean as possible.
- **Upgrades**: DLL hell as a typical example, where upgrading or installing one application can cause a failure to another application due to shared dynamic libraries.
- **Administrator queries**
- **Incident migitation**: both reproduce the old package and the old configuration.
- **Variability**: software may have different compile options, and may only deploy a subset of components. Especially for OSS, packages with the same name and the same version may be compiled from different source.
- **Maintenance**
- **Heterogeneous network**: different set of components may be deployed to different machines according to hardware differences. Even for the same software, compiler options may differ (e.g. enable AVX512?)

Blood pressure rising? That's what we are dealing with on a daily basis :P

:::

# Solutions?

# Nix: as build system

# Nix: as package manager

# NixOS

---

::: { .r-stack }

![[Repository size/freshness map](https://repology.org/repositories/graphs) (2024-05-14)](./images/repology-20240514-zoomed.svg){ .fragment .fade-out data-fragment-index="0" style="max-width:80%" }

![[Repository size/freshness map](https://repology.org/repositories/graphs) (2024-05-14)](./images/repology-20240514.svg){ .fragment .current-visible data-fragment-index="0" style="max-width:80%" }

:::

# References

- [Dolstra, Eelco. The purely functional software deployment model. Utrecht University, 2006.](https://edolstra.github.io/pubs/phd-thesis.pdf)
  