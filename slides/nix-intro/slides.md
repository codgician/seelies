---
author: [ codgician ]
title: 'Introducing Nix'
subtitle: Declarative builds and deployments
date: 2024.05.20
---

# Problems

::: { .incremental }
- Software should still work when distributed among machines.
- Not the reality. Following challenges: 
  * Environment issues
  * Managability issues

:::

## Environment issues

::: { .incremental }
- Components have *dependencies*.
- Dependencies need to be compatible.
- Dependencies should be discoverable.
- Components may depend on **non-software artifacts** (e.g. configurations).

:::

::: { .notes }

- Dependencies: both build time and run time. Especially in OSS world, hard to know which source is the component built from.
- Compatibility: Even for non ABI breaking changes, implementation may change and cause side-effects.
- Needs to be able to find them (e.g. dynmaic linker search path).
- Non-software artifacts, e.g. database, user configurations.

:::

---

## Manageability issues

::: { .incremental }

- **Uninstall / Upgrade**: should not induce failures to another part of the system (e.g. *[DLL hell](https://en.wikipedia.org/wiki/DLL_Hell)*).
- **Administrator queries**: file ownership? disk space consumption? source?
- **Rollbacks**: able to undo effects of upgrades.
- **Variability**: build / deployment configurations may differ.
- ... and they scale for a **huge** fleet of machines with **different SKUs**.

:::

::: { .notes }

- **Uninstall**: also should be as clean as possible.
- **Upgrades**: DLL hell as a typical example, where upgrading or installing one application can cause a failure to another application due to shared dynamic libraries.
- **Administrator queries**
- **Rollbacks**: both reproduce the old package and the old configuration.
- **Variability**: software may have different compile options, and may only deploy a subset of components. Especially for OSS, packages with the same name and the same version may be compiled from different source.
- **Heterogeneous network**: different set of components may be deployed to different machines according to hardware differences. Even for the same software, compiler options may differ (e.g. enable AVX512?)

Blood pressure rising? That's what we are dealing with on a daily basis :P

:::

# Industry solutions?

## Idea #1. Global package management

::: { .incremental }
- Systematically manage packages (e.g. apt, yum, pacman, etc).
- Each component provide a set of constraints:
  - A is installed $\rightarrow$ B (>= 1.0) must be installed.
  - A is installed $\rightarrow$ C should NOT be installed.
  - Success deployment $\rightarrow$ pkg1, pkg2, ... is installed.
- Solve: success deployment.
  
:::

::: { .fragment .fade-in style="color:red" }
[B-SAT](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem) problem (NP-complete).

:::

::: { .fragment .fade-in }
Implement pseudo-solvers.
:::

---

*When you try to manage the global system,*

*you lose isolation.*

::: { .fragment .semi-fade-out data-fragment-index="1" }
- Two components want different versions of the same dependency?
- Two components providing files on the same location?

:::

::: { .fragment data-fragment-index="1" }
- Upgrading is **destructive**, and not atomic.
- Files are usually overwritten, making rollbacks non-trivial.

:::


## Idea #2. Go monolithic!

::: { .incremental }
- Environment issues? 
  - Resolving undeterministic dependency is hard.
  - Why not **bundle everything**?
- Managability issues? 
  - **Isolation** between bundles.
  - Only load dependencies which are bundled inside.
- Self-contained packaging: AppImage, most Windows/macOS apps, etc.
- Containers, and virtualization based technologies.

:::

::: { .notes }

Why do we need a SAT model for package management? It is because packages are not deterministic (e.g. they can depend on different versions of a component through upgrading).

What if we make the packages deterministic? Due to the nature of globality, upgrading one package will require upgrading all other packages sharing dependencies.

Fine. Then why not bundle everything altogether? 

:::

---

*Wait, won't build + deployment be complex due to monolithic?*

::: { .fragment }
Chunking.
:::

::: { .r-stack }

::: { .fragment .fade-in-then-out }
- Break big software into multiple parts. 
  - Inside each part, we go monolithic.
  - Between parts, apply simpler dependency management.
:::

::: { .fragment .fade-in-then-out }
- Break complex build and deployment into multiple stages.
  - Inside each stage, we go imperative.
  - Between xstages, we declaratively define dependencies.
:::

::: { .fragment }
- Break huge docker image into multiple layers.
  - Inside each layer, we go imperative.
  - Between layers, apply simpler dependency management.
:::
:::

::: { .notes }

What is chunking?
- Imagine you need to data structure with both fast random access, and fast random insertion/deletion, and you find Balanced Trees to hard to implement.
- Notice that:
  - Arrays have O(1) random access, but O(N) random deletion / insertion.
  - Linked lists have O(N) random access, but O(1) random deletion / insertion.
- Partition N data into $\sqrt{N}$ chunks.
  - Use linked list between chunks, and array within each chunk.
  - $O(\sqrt{N})$ for both operations.
:::

---

*But we sacrifice sharing between components.*

- How many Electrons do you have in Windows/macOS?
- How many Linux base images do you have in your K8s cluster?

::: { .notes }
- There are optimizations, but coarse-grained.
- Split into layers and share common bases.
:::

## Idea #3

*Can we marry isolation with fine-grained package management?*

::: { .fragment .fade-in-then-semi-out data-fragment-index="5" }
- Environment issues:
  - Do we really need SAT model for dependency management?
  - Much simpler if dependency is just a deterministic tree.
- Managability issues:
  - Store components isolately without bundling?
  - Let components see dependencies in separate views?
:::

# ![](./images/nix-logo.svg){ style="height:72;width:72" } Nix

Originating from [The Purely Functional Software Deployment Model](https://edolstra.github.io/pubs/phd-thesis.pdf) (2006),

Nix solves all above problems,

while achieving decalrative builds & deployments.

::: { .fragment }
```bash
# Works for any Linux distribution and macOS
curl https://nixos.org/nix/install | sh
```
:::

::: { .notes }

Nix is not the only implementation, we also have [Guix](https://guix.gnu.org/nb-NO/blog/2006/purely-functional-software-deployment-model/) inspired by the same thesis.

:::

# Nix: build system

*Deterministic software building makes dependencies deterministic.*

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

## Derivation

::: { .incremental }
- In Nix, we call the smallest unit of compliation as [*derivation*](https://nixos.org/manual/nix/stable/language/derivations).
- A *derivation* is written in a Purely Functional Programming Language (Nix).
- A *derivation* must have all inputs **explictly** specified.
- A *derivation* is built inside a **sandbox** to avoid global state.
- Therefore, the build output of a *derivation* is deterministic.
:::

::: { .notes }

- You know the output path without building the derivation. This is important for binary cache.

:::

## Nix store

::: { .incremental }

- *Derivations* are stored in Nix Store, and builds output to Nix Store.
- A *derivation*'s build inputs are also managed in Nix Store.
- Nix store paths made unique with cryptographic hash:

  ```
  /nix/store/zrwzkd3szh13zd3wrlzj0kdkgiv1xzjn-hello.drv
  /nix/store/rq6w0k38h7kbh2s9snwpysk5yph2fqbf-hello
  ```
  - Prevents interference between components.
- The output path's hash is generated by derivation content.
  - Any slight change to build process is reflected in hash.
:::

::: { .notes }

Question: why hash? 
- If any input / build changes, hash changes.
- Then they will be recognized as different packages.

Question: why output hash is different from derivation hash?
- Because output hash is a part of the derivation content.
- Hash when the output path is empty -> output hash.
- Hash after including output hash -> derivation hash.

Question: why don't we hash based on build output?
- For caching. You want to know the hash before build to prevent rebuilding.

:::

## Sandboxing

::: { .incremental }
- Builds only see specified inputs, and no other files.
  - Assume nothing in global paths like `/lib`, `/usr/bin`, etc.
- Private version of `/proc`, `/dev`, `/dev/shm` and `/dev/pts` (Linux-only).
  - Therefore, private PID, mount, IPS, UTS namespace, etc.
  - No networking access during build.
:::

---

::: { .r-stack }
::: { .fragment .fade-out data-fragment-index="1" }

An example "hello world" program:

```c { .r-stretch .s-full-width }
/* ./src/main.c */
#include <stdio.h>

int main() {
    printf("Hello, World!");
    return 0;
}
```
:::

::: { .fragment .fade-in-then-out data-fragment-index="1" }

... and how we write derivation for it:

```nix { .r-stretch .s-full-width }
{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "hello";
  src = ./src;

  nativeBuildInputs = with pkgs; [ gcc ];
  buildPhase = ''
    gcc main.c -o hello
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin
  '';
}
```
:::

::: { .fragment .fade-in-then-out data-fragment-index="2" }
```json { .r-stretch .s-full-width }
{
  "/nix/store/87zf1q5dx3dkn597lqq17f1g83y116l6-hello.drv": {
    "args": [ "-e", "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh" ],
    "builder": "/nix/store/0c337gsdfjf3162avbkchh0yh4qbs2s3-bash-5.2-p15/bin/bash",
    "env": {
      "buildPhase": "gcc main.c -o hello\n",
      "builder": "/nix/store/0c337gsdfjf3162avbkchh0yh4qbs2s3-bash-5.2-p15/bin/bash",
      "installPhase": "mkdir -p $out/bin\ncp hello $out/bin\n",
      "name": "hello",
      "nativeBuildInputs": "/nix/store/hc326d04c91h73ndqdx3qkggsk730kf2-gcc-wrapper-12.3.0",
      "out": "/nix/store/8ygc7ks9ggj7p2q0b98w1axc3mkyi68c-hello",
      "outputs": "out",
      "src": "/nix/store/92m3yxqi2hfmj75b053zvj0kkhv9bplq-src",
      "stdenv": "/nix/store/iszb73m627pq8v3gwf7zl6xaw01ln2hj-stdenv-linux",
      "system": "aarch64-linux"
    },
    // to be continued...
}}
```
:::
::: { .fragment }
```json { .r-stretch .s-full-width }
{{ // continuing 
    "inputDrvs": {
      "/nix/store/f27pfz65b77lby39rrr48ps21pa6mbxj-gcc-wrapper-12.3.0.drv": {
        "outputs": [ "out" ]
      },
      "/nix/store/hq9032m10smw5qbig1b1cvvqirv61j54-stdenv-linux.drv": {
        "outputs": [ "out" ]
      },
      "/nix/store/nsn38mpj8j5h9861w5chg40f2vz4blq3-bash-5.2-p15.drv": {
        "outputs": [ "out" ]
      }
    },
    "inputSrcs": [
      "/nix/store/92m3yxqi2hfmj75b053zvj0kkhv9bplq-src",
      "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
    ],
    "name": "hello",
    "outputs": {
      "out": { "path": "/nix/store/8ygc7ks9ggj7p2q0b98w1axc3mkyi68c-hello" }
    },
    "system": "aarch64-linux"
  }
}
```
:::
:::

::: { .notes }

- `buildInputs` are explictly specified. No `gcc`.
- Build is split into phases.
- Use `installPhase` to specify build output.

:::

---

::: { .r-stack }
::: { .fragment .fade-out data-fragment-index="1" }

*Another example of hello world with ncurses*

```c { .r-stretch .s-full-width }
/* ./src/main.c */
#include <ncurses.h>

int main() {
    initscr();
    printw("Hello, World!");
    refresh();
    getch();
    endwin();
    return 0;
}
```
:::

::: { .fragment .fade-in-then-out data-fragment-index="1" }

... `ncurses` needs to be explictly specified as `buildInputs`:

```nix { .r-stretch .s-full-width }
{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "hello";
  src = ./src;

  nativeBuildInputs = with pkgs; [ gcc ];
  buildInputs = with pkgs; [ ncurses ];
  buildPhase = ''
    gcc main.c -o hello -lncurses
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin
  '';
}
```
:::

::: { .fragment .fade-in-then-out data-fragment-index="2" }
```json { .r-stretch .s-full-width }
{
  "/nix/store/2w3jmr0s30ylyvpri0m2kb91q4c6wvcb-hello.drv": {
    "args": [ "-e", "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh" ],
    "builder": "/nix/store/0c337gsdfjf3162avbkchh0yh4qbs2s3-bash-5.2-p15/bin/bash",
    "env": {
      "buildInputs": "/nix/store/k7wlgnj0d7fp3862gy0s5s6vphkm48k1-ncurses-6.4-dev",
      "buildPhase": "gcc main.c -o hello -lncurses\n",
      "builder": "/nix/store/0c337gsdfjf3162avbkchh0yh4qbs2s3-bash-5.2-p15/bin/bash",
      "installPhase": "mkdir -p $out/bin\ncp hello $out/bin\n",
      "name": "hello",
      "nativeBuildInputs": "/nix/store/hc326d04c91h73ndqdx3qkggsk730kf2-gcc-wrapper-12.3.0",
      "out": "/nix/store/rmkrazrqfy8zpk1h52qnjrj9qlcyh9mv-hello",
      "src": "/nix/store/yf2fijnfz19kqh8finky3n2rk11217r9-src",
      "stdenv": "/nix/store/iszb73m627pq8v3gwf7zl6xaw01ln2hj-stdenv-linux",
      "system": "aarch64-linux"
    },
}}
```

:::
::: { .fragment }
```json { .r-stretch .s-full-width }
{{ // continuing 
    "inputDrvs": {
      "/nix/store/5l9mg0nlx3j0nf08hlaspnnx592acfm1-ncurses-6.4.drv": {
        "outputs": [ "dev" ]
      },
      "/nix/store/f27pfz65b77lby39rrr48ps21pa6mbxj-gcc-wrapper-12.3.0.drv": {
        "outputs": [ "out" ]
      },
      "/nix/store/hq9032m10smw5qbig1b1cvvqirv61j54-stdenv-linux.drv": {
        "outputs": [ "out" ]
      },
      "/nix/store/nsn38mpj8j5h9861w5chg40f2vz4blq3-bash-5.2-p15.drv": {
        "outputs": [ "out" ]
      }
    },
    "inputSrcs": [
      "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh",
      "/nix/store/yf2fijnfz19kqh8finky3n2rk11217r9-src"
    ],
    "name": "hello",
    "outputs": {
      "out": { "path": "/nix/store/rmkrazrqfy8zpk1h52qnjrj9qlcyh9mv-hello" }
    },
    "system": "aarch64-linux"
  }
}
```
:::
:::

---

::: { .r-stack }
::: { .fragment .fade-out data-fragment-index="1" }

*What if we call other binaries in source?*

```c
#include <stdlib.h>

int main() {
    system("cowsay 'Hello World!'");
    return 0;
}
```

:::

::: { .fragment .fade-in-then-out data-fragment-index="1" }

*Create a wrapper to set `PATH` before actually executing the binary*

```nix { .r-stretch .s-full-width }
{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "hello";
  src = ./src;

  nativeBuildInputs = with pkgs; [ gcc makeWrapper ];
  buildPhase = ''
    gcc main.c -o hello
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin
  '';
  postFixup = ''
    wrapProgram $out/bin/hello \
      --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.cowsay ]}"
  '';
}
```
:::

::: { .fragment .fade-in-then-out data-fragment-index="2" }

*`/bin/hello` is a wrapper script instead of real binary*

```bash { .r-stretch .s-full-width }
$ cat /nix/store/z7i77wwagy58f6svxc8ksm5snsc8wnrm-hello/bin/hello

#! /nix/store/0c337gsdfjf3162avbkchh0yh4qbs2s3-bash-5.2-p15/bin/bash -e
PATH=${PATH:+':'$PATH':'}
PATH=${PATH/':''/nix/store/klqwsfd2xn14bb977d5dvjqdjpp6ka74-cowsay-3.7.0/bin'':'/':'}
PATH='/nix/store/klqwsfd2xn14bb977d5dvjqdjpp6ka74-cowsay-3.7.0/bin'$PATH
PATH=${PATH#':'}
PATH=${PATH%':'}
export PATH
exec -a "$0" "/nix/store/z7i77wwagy58f6svxc8ksm5snsc8wnrm-hello/bin/.hello-wrapped"  "$@" 
```
:::
:::

## Binary cache

::: { .incremental }
- Note that the output hash can be calculated without building the derivation.
- Meaning, we can **cache** the builds easily.
- Serve nix store with a file server, which is the [*binary cache*](https://wiki.nixos.org/wiki/Binary_Cache).
- Packages can be signed before being added to binary cache or on the fly as they are served.
:::

## [NixPkgs](https://github.com/nixos/nixpkgs)

*There are many languages/frameworks, complicated.*

- Why not unite the efforts in building software?
- Nixpkgs provides not only compiler toolchains, but also infrastructure for packaging applications written in various language and frameworks.
- And of course, it comes with an official binary cache.

---

*It seems to restrictive for majority packages to onboard?*

[Nix Search - Packages](https://search.nixos.org)

[Repology](https://repology.org/repositories/graphs)

::: { .fragment }

Take [rust-analyzer](https://github.com/NixOS/nixpkgs/blob/9a50b221e403694b0cc824fc4600ab5930f3090c/pkgs/development/tools/rust/rust-analyzer/default.nix) as a real-life example.

:::

::: { .notes }

In repology, packages are deduped.

:::

# Nix: package manager

*Build makes little sense if we cannot install it.*

::: { .fragment }

- Search for references recursively for a package's derivation,
- we get a package's *closure*, 
- that is, itself and all its direct and transitive runtime dependencies.

:::

## Installation

::: { .fragment .semi-fade-out data-fragment-index="1" }

Two possibilities:

- The closure is already in store or binary cache,
- It has to be built fresh (then we infer the closure).

:::

::: { .fragment data-fragment-index="1" }
*How to make the package accessible?*
:::

::: { .fragment }
- *Activation script*: an idempotent script making things accessible.
- e.g. add all package outputs to `$PATH`.
- Executed while initializing profile.
  ```bash
  nix-shell -p hello
  ```
:::

## Removal

Garbage collection.

::: { .incremental }
- Register it as gcroot when installing a derivation.
- Deregister after uninstalling.
- Periodically, enumerate all reachable store paths from the gcroots, and remove all unreachable paths. 
  ```bash
  $ nix-collect-garbage
  ```
:::

## Advantages

::: { .incremental }
- Deterministic dependencies. No SAT solver.
- Different versions / variants of the same package can be installed together.
- Zero assumption about system global state.
- Atomic installs / upgrades.
:::


# NixOS

::: { .fragment .semi-fade-out data-fragment-index="1" }
*A working system = Software + Configurations*
:::

::: { .fragment data-fragment-index="1"  }
*Why separate packages and configurations?*

NixOS leverages Nix to manage both altogether.
:::

---

::: { .r-stack }

::: { .fragment .fade-out data-fragment-index="1" }
[Filesystem Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)

```
/
├── boot
├── bin
├── etc
├── lib
├── usr
│  ├── bin
│  ├── include
│  ├── lib
│  └── share
```
:::

::: { .fragment data-fragment-index="1" }

*However, in NixOS ...*

```{ .r-stretch }
/
├── boot
├── nix
│  ├── store
│  │  ├── acr...kl-nixos-system-...
│  │  ├── 11w...cv-nixos-system-...
│  │  │  ├── activate
│  │  │  ├── kernel -> /nix/store/bcd...3h-linux-6.6.30/bzImage
│  │  │  ├── systemd -> /nix/store/9cx...8s-systemd-255.4
│  │  │  ├── ...
│  │  ├── bcd...3h-linux-6.6.30
│  │  ├── 9cx...8s-systemd-255.4
│  │  ├── ...
│  ├── var/nix/profiles
│  │  ├── system -> system-250-link
│  │  ├── system-249-link -> /nix/store/acr...kl-nixos-system-...
│  │  ├── system-250-link -> /nix/store/11w...cv-nixos-system-...
```

- *Activation script*: `/nix/var/nix/profiles/system/activate`

:::
:::

---

*Declaratively describe your system in Nix*:

```nix { .r-stretch }
{ config, lib, pkgs, ...}: {
	# Use systemd-boot EFI bootloader
	boot.loader.systemd-boot.enable = true;
	# Kernel configurations
	boot.supportedFilesystems = [ "bcachefs" ];
	boot.initrd.availableKernelModules = [ "xhci_pci" "sr_mod" ];
  	boot.kernelPackages = pkgs.linuxPackages_latest;
	# Use zsh for shell
 	programs.zsh.enable = true; 
	programs.zsh.enableCompletion = true;
	# Enable the OpenSSH daemon.
  	services.openssh.enable = true;
	# Configure users
	users.users.codgi = {
		name = "codgician";
		home = "/home/codgi";
		shell = pkgs.zsh;
		openssh.authorizedKeys.keys = [ "..." ];
	};
}
```

- Nixpkgs also provide configuration modules, [search here](https://search.nixos.org/options?).
- How I manage my devices: [github:codgician/serenitea-pot](https://github.com/codgician/serenitea-pot).
- Demo.

---

> The power of NixOS roots in the Nix language.

- Validate configurations before deployment.
- Reference values accross modules of configurations.
- Effeciently reuse configurations.
- Unified language interface for any system component.

## And even more

- Trivial [remote deployment](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment): just push closure over ssh
- [Home manager](https://github.com/nix-community/home-manager): Manage dotfiles under `/home` declaratively using Nix.
- [Impermanence](https://github.com/nix-community/impermanence): Trivially handle persistent states on systems with **ephemeral** root storage

# Ending

::: { .incremental }
- Although I am a Nix enthusiastic, I still realize:
  - Nix is hard to adopt in industry due to steep learning curve.
  - Even if Nix has a novel model, implementations consist many workarounds: 
	sometimes you "hack" software to make it work on Nix.
  - Many existing infra may be "acceptable" enough to make completely refactor everything with Nix not necessary.
:::

---

::: { .fragment .semi-fade-out data-fragment-index="1" }
Nix/NixOS is still gaining increasing visibility and popularity.

[Google trends: NixOS](https://trends.google.com/trends/explore?date=today%205-y&q=NixOS)

:::

::: { .fragment data-fragment-index="1" }
*Embracing Nix without fully switching*

- [Flox: your dev environment everywhere](https://flox.dev)
- [Docker and Nix (DockerCon 2023)](https://www.youtube.com/watch?v=l17oRkhgqHE)
- [Nix, Kubernetes, and the Pursuit of Reproducibility (CNCF 2023)](https://www.youtube.com/watch?v=U-mSWU4see0)
- [Nix and Kubernetes: deployment done right (NixCon 2023)](https://www.youtube.com/watch?v=N7e73UCT69U)

:::

## Thank you!

To get started, or learn further about Nix/NixOS:

- Official website: [nixos.org](https://nixos.org)
- NixOS manual: [nixos.org/manual/nixos/stable](https://nixos.org/manual/nixos/stable/)
- Nix docs: [nix.dev](https://nix.dev)
- NixOS wiki: [wiki.nixos.org](https://wiki.nixos.org)
- Search packages / configurations: [search.nixos.org](https://search.nixos.org)
- Search for functions in nix (lang): [noogle.dev](https://noogle.dev)
  
---

Slides are

generated by [pandoc](https://pandoc.org),

rendered by [reveal.js](https://revealjs.com),

and managed by [Nix](https://nixos.org). 

Fully [open-sourced](https://github.com/codgician/seelies).

## References

- [Dolstra, Eelco. The purely functional software deployment model. Utrecht University, 2006.](https://edolstra.github.io/pubs/phd-thesis.pdf)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Nix: from a build system to an ansible replacement (TUNA)](https://mirrors.tuna.tsinghua.edu.cn/tuna/tunight/2021-05-29-nix/slides.pdf)


# Supplementaries

*Slides not shown by default*

---

*Wait, for `hello-ncurses`, doesn't `gcc` do dynmaic linking by default?*

::: { .incremental }

- Nix has a patched version of dynamic linker in `stdenv`.
  - It never searches global library directories, like `/lib`, `/usr/lib`, etc.
  - The linker adds `-rpath` flag for every library directory mentioned through -L flags.
- Won't this possibly include unnecessary dependencies?
  - We don't know in advance if a library is actually used by the linker.
  - Leverage fix up stage at the end to [patchelf](https://github.com/nixos/patchelf) and shrink rpath.
:::

---

*Wait, how can Nix magically know runtime dependencies?*

::: { .fragment }
> "Runtime dependencies must be a subset of build time dependencies".

- Build time dependencies are explictly specified.
- Runtime dependencies are automatically inferred by:
  - Serializing store paths into NAR,
  - Then search for references to other store paths within it.
:::

::: { .fragment }

*How can this be true and how can it work?*

:::

::: { .fragment style="color:red" }

It just works! 🤪

:::
