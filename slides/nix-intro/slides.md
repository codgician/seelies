---
author: [ codgician ]
title: 'Introducing Nix'
subtitle: Declarative builds and deployments
date: 2024.05.20
---

# Test GraphViz

```{ .graphviz caption="This is an image, created by **Graphviz**'s dot." }
digraph finite_state_machine {
	rankdir=LR;
	size="8,5"
	node [shape = doublecircle]; LR_0 LR_3 LR_4 LR_8;
	node [shape = circle];
	LR_0 -> LR_2 [ label = "SS(B)" ];
	LR_0 -> LR_1 [ label = "SS(S)" ];
	LR_1 -> LR_3 [ label = "S($end)" ];
	LR_2 -> LR_6 [ label = "SS(b)" ];
	LR_2 -> LR_5 [ label = "SS(a)" ];
	LR_2 -> LR_4 [ label = "S(A)" ];
	LR_5 -> LR_7 [ label = "S(b)" ];
	LR_5 -> LR_5 [ label = "S(a)" ];
	LR_6 -> LR_6 [ label = "S(b)" ];
	LR_6 -> LR_5 [ label = "S(a)" ];
	LR_7 -> LR_8 [ label = "S(b)" ];
	LR_7 -> LR_5 [ label = "S(a)" ];
	LR_8 -> LR_6 [ label = "S(b)" ];
	LR_8 -> LR_5 [ label = "S(a)" ];
}
```

# Software deployment

::: { .incremental }
- Source deployment
  $$
  \begin{CD}
  \text{get source} @>>> \text{build} @>>> \text{install} \\
  \end{CD}
  $$
- Binary deployment
  $$
  \begin{CD}
  \text{get binary} @>>> \text{install} \\
  \end{CD}
  $$
:::

## Problems

- Software should be reproducible when copied among machines.
- Challenges: 
  * Most software today is not self-contained.
  * As they scale, deployment process becomes increasingly complex.
- We deal with these everyday at Deployment Team 🤪. 

---

### Environment issues

::: { .fragment  .fade-in-then-semi-out }
- Software today is almost **never self-contained**.
- Dependencies, both build time and run time, needs to be **compatible**. 
- Components need to be able to **find** dependencies. 
- Components may depend on **non-software artifacts** (e.g. databases).
:::

::: { .notes }

- Dependencies: both build time and run time. Especially in OSS world, hard to know which source is the component built from.
- Compatibility: Even for non ABI breaking changes, implementation may change and cause side-effects.
- Needs to be able to find them (e.g. dynmaic linker search path).
- Non-software artifacts, e.g. database, user configurations.

:::

---

### Manageability issues

- **Uninstall / Upgrade**: should not induce failures to another part of the system (e.g. *[DLL hell](https://en.wikipedia.org/wiki/DLL_Hell)*).
- **Administrator queries**: file ownership? disk space consumption? source?
- **Rollbacks**: able to undo effects of upgrades.
- **Variability**: build / deployment configurations may differ.
- **Maintenance**: may have different policies for keeping software up-to-date.
- ... and they scale for a **huge** fleet of machines with **different SKUs**.

::: { .notes }

- **Uninstall**: also should be as clean as possible.
- **Upgrades**: DLL hell as a typical example, where upgrading or installing one application can cause a failure to another application due to shared dynamic libraries.
- **Administrator queries**
- **Rollbacks**: both reproduce the old package and the old configuration.
- **Variability**: software may have different compile options, and may only deploy a subset of components. Especially for OSS, packages with the same name and the same version may be compiled from different source.
- **Maintenance**
- **Heterogeneous network**: different set of components may be deployed to different machines according to hardware differences. Even for the same software, compiler options may differ (e.g. enable AVX512?)

Blood pressure rising? That's what we are dealing with on a daily basis :P

:::

# Industry solutions?

## Idea #1. Let's go monolithic!

Bundle everything to increase reproducibility at runtime.
 
::: { .incremental }
- **Dependencies**? Self-contained packaging!
- **Isolation**? Sandbox technologies!
- **Environment issues**? Containers!
- **Different hardware**? Virtualization!
:::

---

*Wait, this doesn't really simplify build + deployment process.*

::: { .incremental }
- Split build & deployment into *stages* (workflows).
- Manage dependencies between *stages*.
- e.g. GitHub actions, Ansible,  etc.
:::

::: { .notes }

Monolithic only solves running the software in a reproducible manner.
Building and deploying monolithic software could still be complex.

:::

---

*Aren't we wasting storage spaces?*

::: { .incremental }
- Split into layers and share common bases.
- Fetch files on-demand? (e.g. Zero Install System).
- Storage today is getting cheaper anyway...
:::

::: { .notes }

If we habe $N$ apps having $M$ same dependencies, the storage complexity becomes $\mathcal{O}(NM)$ instead of $\mathcal{O}(N + M)$.

Splitting monolithic architecture can never be fine-grained, because its motavation is to prevent management complexity. The more you split, the more you lose benefits of monolithic architecture.

:::

## Idea #2. Package manager

::: { .incremental }
- Each component provide a set of constraints:
  - Hard clauses, e.g. a dependency must exist.
  - Soft clauses, e.g. version as new as possible.
  - Satisfy all hard clauses. Maximize satisfied soft clauses.
:::

::: { .fragment .fade-in style="color:red" }
MAXSAT problem (NP-complete).
:::

::: { .fragment .fade-in }
Implement pseudo-solvers, e.g. rpm, apt, etc.
:::

::: { .notes }

* Package management is especially critical to UNIX systems because they traditionally insist placing packages in global namespaces, following [Filesystem Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard).

:::

---

*But most implementations install components in global namespace...*

::: { .incremental }

- Two components depending different versions of the same package?
- Two components providing file to the same path?
- Two components may interfere with others in the case of incomplete dependencies and inexact notions of component compatibility.

:::

---

::: { .incremental }

- Desctrucitive upgrading: 
  * Upgrades are not atomic.
  * Files are overwritten, making rollback non-trivial.

:::

## Idea #3? 

Let's solve all issues with a **systematic** approach.

Introducing [The Purely Functional Software Deployment Model](https://edolstra.github.io/pubs/phd-thesis.pdf),

and one of its implementation, Nix.

::: { style="justify-content: center" }
```bash
curl https://nixos.org/nix/install | sh
```
:::

::: { .notes }

Nix is not the only implementation, we also have [Guix](https://guix.gnu.org/nb-NO/blog/2006/purely-functional-software-deployment-model/) inspired by the same thesis.

:::

# Nix: a build system

*Building software is just a function.*

$$
\begin{CD}
\text{Inputs}  @> f>> \text{Output}
\end{CD}
$$

::: { .r-stack }
::: { .fragment .fade-out data-fragment-index="1" }
$$
\begin{CD}
x = 1, y = 2 @> f(x, y) = x + y >> 1 + 2 = 3
\end{CD}
$$
:::
::: { .fragment .current-visible data-fragment-index="1" }
$$
\begin{CD}
\text{gcc, libc, source, ...} @> \text{./configure, make, make install} >> \text{binary}
\end{CD} 
$$
:::
:::

## Why pure function?

::: { .incremental }

- Reproducible.
  * The same inputs always yield the same output.
- No side-effects.
  * Calculation of one function never interfere other functions.
- Cachable.
  * Safe to cache computed results.

:::

## But how?

::: { .incremental }

- Require explicit dependency declaration.
- Ensure by building in a *clean* sandbox.
- In Nix, we call the smallest unit of compliation as *derivation*.
- A *derivation* is written in a functional programming language, also named Nix.

:::

## Derivation

```nix
```

## Nix Store


# Nix: as package manager

# NixOS


---

::: { .r-stack }

![[Repository size/freshness map](https://repology.org/repositories/graphs) (2024-05-14)](./images/repology-20240514-zoomed.svg){ .fragment .fade-out data-fragment-index="0" style="max-width:80%" }

![[Repository size/freshness map](https://repology.org/repositories/graphs) (2024-05-14)](./images/repology-20240514.svg){ .fragment .current-visible data-fragment-index="0" style="max-width:80%" }

:::

# References

- [Dolstra, Eelco. The purely functional software deployment model. Utrecht University, 2006.](https://edolstra.github.io/pubs/phd-thesis.pdf)
  
---

Slides are

generated by [pandoc](https://pandoc.org),

rendered by [reveal.js](https://revealjs.com),

and managed by [Nix](https://nixos.org). 

Fully [open-sourced](https://github.com/codgician/seelies).
