---
author: [ "codgician" ]
title: Package Upgradability
subtitle: 📦 The algorithm behind "packup"
date: 2022.09.23
---

# Modelling

## Inputs and outputs

- Inputs:
  - **Package universe**: A set of packages containing *versions*, *dependencies*, *conflicts* and other metadata.
  - **User request**: The packages to be *installed*, *removed*, *updated*, etc.

- Output: A solution satisfying constraints between the packages and the user request.

- **CUDF** (Common Upgradability Description Format) by MANCOOSI project.

## Package description

- Denote as a partial function $\phi$, when given package $p$ with version $v$, it returns a tuple containing:
  - $\phi(p, v).installed$
    - `true` or `false`
  - $\phi(p, v).conflicts, \phi(p, v).depends$
    - A set of constraints $(p, relop, n)$
    - $relop$: $=, \ne, \ge, \le$

## User request

- A pair of sets of constraints: $(l_i, l_d)$
  - $l_i$: packages must be installed
  - $l_d$: packages must be removed

## Solution

- Another package description $\psi$, which:
  - $\psi$ differs from $\phi$ only in the $installed$ properties;
  - all $depends$ properties are satisfied;
  - no $conflicts$ are violated in $\psi$;
  - $l_i, l_d$ (packages must be installed / removed) are met;

## Measuring solution

- Factors:
  - $removed(\phi, \psi) = |\{ p \mid i_\phi(p) \neq \emptyset \land i_\psi(p) = \emptyset \}|$
  - $new(\phi, \psi) = |\{ p \mid i_\phi(p) = \emptyset \land i_\psi(p) \neq \emptyset \}|$
  - $changed(\phi, \psi) = |\{ p \mid i_\phi(p) \neq i_\psi(p)\}|$
  - $notuptodate(\phi, \psi) = |\{ p \mid i_\psi(p) \neq \emptyset \land v_\text{max} \not\in i_\psi(p) \}|$
- Criterion: a tuple $\tau = (f_1, \dots, f_n)$ where $f_i$ is one of the factors defined above. 
- Compare in lexigraphic ordering.

# Encoding

Leveraging propositional logic, the problem could be encoded as a weighted partial MAXSAT formula with:

- **hard clauses**: constraints MUST be satisfied
- **soft clauses**: constraints with a weight $W_i$, preferrably satisfied.

**Goal**: Maximize the sum of weights of satisfied soft clauses.

## Denotations

Wether or not...

- $x_p^v$: version $v$ of package $p$ is installed
- $u\uparrow^{v}_{p}$: all versions $\ge v$ of package $p$ are uninstalled
- $u\downarrow^{v}_{p}$: all versions $\le v$ of package $p$ are uninstalled
- $i\uparrow^{v}_{p}$: exists a version $\ge v$ of package $p$ is installed
- $i\downarrow^{v}_{p}$: exists a version $\le v$ of package $p$ is installed

## Conflicts

If version $v$ of package $p$ conflicts with version $\le n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** all versions $\le n$ of package $q$ are uninstalled.

$$
C[x_p^v, (q, \le, n)] = \neg x_p^v \lor u\downarrow_q^n
$$

---

If version $v$ of package $p$ conflicts with version $\ge n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** all versions $\ge n$ of package $q$ are uninstalled.

$$
C[x_p^v, (q, \ge, n)] = \neg x_p^v \lor u\uparrow_q^n
$$

---

If version $v$ of package $p$ conflicts with version $n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** versions $n$ of package $q$ is uninstalled.

$$
C[x_p^v, (q, =, n)] = \neg x_p^v \lor \neg x_q^n
$$

---

If version $v$ of package $p$ conflicts with version $\neq n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** all versions $\neq n$ of package $q$ are uninstalled.

$$
C[x_p^v, (q, \neq, n)] = (\neg x_p^v \lor u\downarrow^n_q) \land (\neg x_p^v \lor u\uparrow^n_q)
$$

---

For package $p$ with version $v$, denoting its set of conflict constraints as $l$: 

$$
C[x_p^v, l] = \bigwedge_{r \in l} C[x_p^v, r]
$$

## Dependencies

If version $v$ of package $p$ depends on any version $\le n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** exists a version $\le n$ of package $q$ is installed.

$$
D[x_p^v, (q, \le, n)] = \neg x_p^v \lor i\downarrow_q^n
$$

---

If version $v$ of package $p$ depends on any version $\ge n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** exists a version $\ge n$ of package $q$ is installed.

$$
D[x_p^v, (q, \ge, n)] = \neg x_p^v \lor i\uparrow_q^n
$$

---

If version $v$ of package $p$ depends on version $n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** version $n$ of package $q$ is installed.

$$
D[x_p^v, (q, =, n)] = \neg x_p^v \lor x_q^n
$$

---

If version $v$ of package $p$ depends on any version $\neq n$ of package $q$:

- **either** version $v$ of package $p$ is not installed,
- **or** exists a version $\neq n$ of package $q$ is installed.

$$
D[x_p^v, (q, \neq, n)] = \neg x_p^v \lor i\downarrow_q^n \lor i\uparrow_q^n
$$

---

Dependency constraints could be "depending on both" or "depending on either":

$$
D[x_p^v, l_1 \oplus l_2] = D[x_p^v, l_1] \oplus D[x_p^v, l_2] \text{, where } \oplus \in \{\land, \lor \}
$$

## Make our denotations work

- When $u\uparrow_p^v$ is `true`:
  - package $p$ of version $v$ can't be installed, so $x_p^v$ must be `false`
  $$
  \neg u\uparrow_p^v \lor \neg x_p^v
  $$
  - package $p$ of version $> v$ should also be uninstalled, so $u\uparrow_p^{v + 1}$ should also be `true`
  $$
  \neg u\uparrow_p^v \lor u\uparrow_p^{v + 1}
  $$

---

- When $u\downarrow_p^v$ is `true`:
  - package $p$ of version $v$ can't be installed, $x_p^v$ must be `false`
  $$
  \neg u\downarrow_p^v \lor \neg x_p^v
  $$
  - package $p$ of version $< v$ should also be uninstalled, so $u\downarrow_p^{v - 1}$ should also be `true`
  $$
  \neg u\downarrow_p^v \lor  u_p\downarrow^{v - 1}
  $$

---

- When $i\uparrow_p^v$ is `true`:
  - **either** package $p$ with version $v$ is installed: $x_p^v$
  - **or** exists a package version $>v$ is installed: $i\uparrow_p^{v + 1}$

$$
\neg i\uparrow_p^v \lor (x_p^v \lor i\uparrow_p^{v+1})
$$

---

- When $i\downarrow_p^v$ is `true`:
  - **either** package $p$ with version $v$ is installed: $x_p^v$
  - **or** exists a package version $<v$ is installed: $i\downarrow_p^{v - 1}$

$$
\neg i\downarrow_p^v \lor (x_p^v \lor i\downarrow_p^{v-1})
$$

---

Therefore, for each package $p$ with version $v$, we generate:

$$
\begin{aligned}
I_p^v = & (\neg u\uparrow_p^v \lor \neg x_p^v) \land (\neg u\uparrow_p^v \lor u_p^{v + 1}) \\
& \land (\neg u\downarrow_p^v \lor \neg x_p^v) \land (\neg u\downarrow_p^v \lor  u_p^{v - 1}) \\
& \land (\neg i\uparrow_p^v \lor x_p^v \lor i\uparrow_p^{v+1}) \land (\neg i\downarrow_p^v \lor x_p^v \lor i\downarrow_p^{v-1})
\end{aligned}
$$

## The hard constraints

- For package description $\phi$ and user request $(l_i, l_d)$, denote $r$ as a "dummy" always-installed package:
$$
\begin{aligned}
r & \land D(r, l_i) \land C(r, l_d) \land \bigwedge I_p^v \\
& \land \bigwedge_{(p, v) \in Dom(\phi)} D[x_p^v, \phi(p, v).depends] \land C[x_p, \phi(p, v).conflicts]
\end{aligned} 
$$

## The soft constraints

- Denote $i_\phi(p)$ as ta set of versions of a given package $p$.
- $removed(\phi, \psi)$:
  - If $i_\phi(p) \neq \emptyset$, generate $i\uparrow_p^1$ with $W_r$
  - Higher score when less packages are removed.
- $new(\phi, \psi)$:
  - If $i_\phi(p) \neq \emptyset$, generate $u\uparrow_p^1$ with $W_n$
  - Higher score when less new packages are installed.

---

- $change(\phi, \psi)$:
  - Let $s_p$ be a fresh variable
  - **Hard clause**: (different clause needed for different installed state in $\phi$)
    $$
    \begin{cases}
    \neg s_p \lor x_p^v & (\phi(p, v).installed = true) \\
    \neg s_p \lor \neg x_p^v & (\phi(p, v).installed = false)
    \end{cases}
    $$
  - **Soft clause**: $s_p$ with $W_c$
  - Higher score when less packages are changed

---

- $notuptodate(\phi, \psi)$:
  - Let $t_p$ be a fresh variable
  - **Hard clause**: (ensure that only installed packages are taken into account)
    - $\neg x_p^v \lor t_p$ for all $(p, v) \in Dom(\psi)$
  - **Soft clause**: $\neg t_p \lor x_p^{v_\text{max}}$ with $W_{nu}$
  - Higher score when more packages are up-to-date.

# Implementation progress

**🚧 Still work in progress...**

- We planned to leverage Microsoft.Z3 as the SAT/SMT solver, but Z3 has no built-in MAXSAT support.
- We are researching different MAXSAT algorithms to implement our algorithm so that the project code could be completely C#.

# References

- [Janota, M., Lynce, I., Manquinho, V. and Marques-Silva, J., 2012. **PackUp: Tools for package upgradability solving.** Journal on Satisfiability, Boolean Modeling and Computation, 8(1-2), pp.89-94.](https://content.iospress.com/download/journal-on-satisfiability-boolean-modeling-and-computation/sat190090?id=journal-on-satisfiability-boolean-modeling-and-computation%2Fsat190090)
