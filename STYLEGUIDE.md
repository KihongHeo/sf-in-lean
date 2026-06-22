# SFL Style Guide

BCP: This needs careful review and tidying

This file records the conventions and the most important decisions we have made
about writing *Software Foundations in Lean* (SFL): Lean coding style, Verso
markup, comment conventions, and the order in which tactics are introduced.

It is meant to be the *consolidated, normative* reference. [COMMENTARY.md](COMMENTARY.md)
remains the running scratchpad where rationale, open questions, and per-chapter
notes are first discussed; once a decision settles, it belongs here. See
[README.md](README.md) for the project's tenets and the contribution/CI workflow.

> Overarching tenets (from the README): SFL aims for **exceptional pedagogy and
> presentational polish**; it is **exercise-based**; it teaches **proof
> engineering** — readable, maintainable, *idiomatic* Lean, with tactics
> introduced "starting small and growing in sophistication." When a pedagogical
> goal and an engineering ideal conflict, prefer idiomatic Lean and deviate only
> temporarily, with explanation.

## File organization

Each chapter exists in two forms:

* **`LF/<Chapter>.lean`** — the *code-forward* source. Prose lives in `/- … -/`
  block comments; the Lean code is the spine of the file. This is what authors
  edit.
* **`LF/<Chapter>Verso.lean`** — the *docs-forward* Verso file, **generated** by
  [scripts/to_verso.py](scripts/to_verso.py). Do not hand-edit; regenerate
  instead (`python3 scripts/to_verso.py LF/<Chapter>.lean LF/<Chapter>Verso.lean`).

**Exception:** `LF/Basics.lean` is authored *directly in Verso* (prose is raw
Verso markup; code lives in ` ```lean ` fences). `CustomTactics.lean` is plain
support Lean. These are the two `DIRECT_LF_MODULES` in `to_verso.py`; an
`import LF.X` of one passes through unchanged, while any other `import LF.X` is
rewritten to `import LF.XVerso`.

Three HTML variants are produced under `_out/` (`make`): **student** (full
prose, solutions elided), **solutions** (full prose, solutions shown), **terse**
(lecture/live-coding prose, solutions elided). Always make sure `lake build`
passes before opening a PR; `main` must always build.

## Lean style

Follow the [Mathlib style guide](https://leanprover-community.github.io/contribute/style.html)
and the Lean linter by default. 

SFL-specific conventions:

* **Structured `cases`/`induction`.** Prefer
  ```lean
  cases b
  case true  => …
  case false => …
  ```
  over `cases b with | …` *and* over the bare `·` goal selector — i.e. prefer
  `cases h; case …` / `induction h; case …`. Select cases with named `case`s,
  un-indented and without a leading `.`, and **align the `=>`** as above.
  Use the `·` selector only when the goal names are not meaningful.
* **`rewrite` before `rw`** (see next section).
* **Explicit rewrites over `dsimp`/`simp` through notation** (see "Notation and
  simplification").
* **`sorry` placeholders are checked, not silent.** Where a `sorry` appears
  (incomplete proof, exercise scaffold), wrap it so the warning is asserted:
  ```lean
  /-- warning: declaration uses `sorry` -/
  #guard_msgs in
  example : … := sorry
  ```
* **Aborted/abandoned lemmas** become unnamed `example`s closed with `sorry`
  (the SFL analogue of Rocq's `Abort`).
* **Library vs. client code.** Inside a definition's own library it is fine to
  unfold and simplify through definitions; *using* that code, do not "peek
  through the interface."

### `rewrite` vs `rw`

`rw [h]` is roughly `rewrite [h]; rfl`, which is too strong for the first
chapters: it hides the closing `rfl` and makes proofs step confusingly (the goal
vanishes when you step past the final `]`). Decision (JC): **use `rewrite` the
first time, keep using it explicitly in the early arithmetic proofs, then
introduce `rw` in `Induction` and use `rw` predominantly from there on.**

### Notation and simplification

When notation is implemented via typeclass instances, `dsimp [add]` /
`dsimp [app]` do *not* resolve the instance down to the underlying definition,
and `simp` is often too powerful for teaching. So **rewrite explicitly by
equational lemmas** instead — e.g. `n + (m + 1) = n + m + 1` or
`(h :: t) ++ l = h :: t ++ l` — rather than reaching for `dsimp`/`simp`.

### Arithmetic / the custom `Nat`

`Basics` defines its own `Nat` with `zero`/`succ` constructors and overrides the
stdlib typeclasses for `-`, `*`, and `^` (but **not** `+`, which is too
pervasive in the stdlib to shadow safely). Write arithmetic proofs against these
definitions (`add_succ`, `add_zero`, `mul_succ`, …). `calc`-style equational
reasoning is introduced in `Induction`.

## Tactics: order of introduction

A core pedagogical decision is that tactics are introduced gradually. The table
below lists the tactics **first introduced** in each chapter, in chapter order.
It is derived from the current sources (tactic-position occurrences in real
code, comments excluded) and should be kept in sync as chapters are rewritten;
chapters past `Logic` are still in flux.

| Chapter           | Tactics first introduced |
|-------------------|--------------------------|
| `Basics`          | `rfl`, `intro`, `rewrite`, `cases`, `exact` |
| `Induction`       | `induction`, `have`, `rw`, `calc`, `generalize` |
| `Lists`           | `dsimp` |
| `Poly`            | *(none new)* |
| `Tactics`         | `intros`, `apply` (and `apply … at`), `replace`, `symm`, `injection`, `injections`, `congr`, `assumption`, `contradiction`, `unfold`, `split` |
| `Logic`           | `constructor`, `obtain`, `left`, `right`, `ext`, `by_cases`, `exfalso` |
| `IndProp`         | `simp`, `rcases`, `subst`, `omega` |
| `Maps`            | *(none new)* |
| `IndPropRegexp`   | `specialize`, `trivial` |
| `UsingLean`       | *(none new)* |

Related notation introduced alongside tactics: anonymous constructor `⟨…⟩`
(`Lists`); destructuring `let ⟨…⟩ := …` and `cases h : …`,
`induction … generalizing …` (`Tactics`); projection/`Iff` syntax `.left`,
`.right`, `.mp`, `.mpr`, and rewriting by an `↔` (`Logic`).

**Tactics deliberately deferred / under discussion** (per FPiL's caution that
`grind` is overwhelming for beginners): candidates still to be placed include
`show`, `rename_i`, `revert`, `subst`, `suffices`. Powerful automation
(`simp` heavy use, `tauto`, `omega`, `decide`) is concentrated in a future
**Automation** chapter; `grind`, `aesop`, and `try` are deferred to a later
volume. The `RegExp` development moves out of `IndProp` into that Automation
chapter.

## Verso markup and `to_verso` conventions

BCP: This material is temporary -- to_verso.py is going to go away at some point.

`to_verso.py` turns the code-forward source into Verso. Authors write ordinary
block comments and a small set of markers; the script maps them to directives:

| Source marker                         | Verso result |
|---------------------------------------|--------------|
| `/- ## Title -/`                      | section heading |
| `-- FULL` … `-- /FULL`                | `:::full` block |
| `-- TERSE: /- … -/`                   | `:::terse` block |
| `-- TERSE: /- *** -/`                 | `:::slidebreak` |
| `-- EX1 (name)` … `-- []`             | `:::exercise (rating := N) (name := "…")` (closed by `-- []`) |
| `/- BCP: … -/`, `/- JC: … -/`, etc.   | `:::dev` block (author/dev note) |
| `-- GRADE_THEOREM <pts>: <name>`      | `:::grade` (no-op now; drives grading later) |
| `-- INSTRUCTORS:`                     | `:::instructors` |
| `-- HIDE` / `HIDEFROMADVANCED` / `HIDEFROMHTML` | `:::hide` |
| BNF grammar blocks                    | `:::bnf` |
| ordinary `/- … -/` prose              | Verso prose |
| anything else                         | ` ```lean ` code block |

Directives currently in use: `dev`, `full`, `terse`, `slidebreak`, `exercise`,
`grade`, `hide`, `solution`, `instructors`, `bnf` (defined under
[SFLMeta/](SFLMeta/)).

**Intentionally dropped by `to_verso` — do not treat as content loss:**

* `/- test_* -/` single-identifier test-case labels (decided 2026-06-15).
* Hand-written Lean output annotations `/- ==> … -/` and `/- ===> … -/`: Verso's
  InlineLean renders the *real, verified* output live, so these drift-prone
  copies are redundant.
* `####…` separator/divider lines in comments.
* The marker keywords themselves once consumed: `ADMITDEF`, `ADMITTED`,
  `SOLUTION`, `FULL`, `TERSE`, `HIDE`, `EX`/`EX1`/…, `GRADE_THEOREM`,
  `GRADE_MANUAL`, `INSTRUCTORS`.

**Must be preserved** (these were bugs, now fixed): block-style author notes
(`/- MWH: … -/`, `/- BCP: … -/`) → `:::dev`; `-- GRADE_THEOREM …` → `:::grade`.

To check a chapter survived translation: regenerate `<Ch>Verso.lean`, then
confirm every identifier/number token and comment word in `<Ch>.lean` appears in
the Verso output, excluding the intentionally-dropped tokens above.

## Comments

In comments, use Markdown (it renders in VS Code).

**Line comments (`--`)** are for:
* Instructor/author notes, e.g. `-- BCP:`, `-- JC:`.
* Section dividers and headings: `-- #`, `-- ##`, ….
* Directives: `-- FULL`, `-- /FULL`, `-- TERSE`, `-- ADMITTED`, `-- ADMIT_DEF`,
  `-- GRADE_THEOREM`, `-- []`, `-- HIDE`, `-- HIDEFROMADVANCED`,
  `-- HIDEFROMHTML`.

**Block comments (`/- … -/`)** are for student-facing prose, optionally prefixed
by a directive (`/- FULL: … -/`, `/- TERSE: … -/`). Use:
* `#` / `##` / … for section, subsection headers.
* `*` (not `-`) for unnumbered list items.

**Doc comments (`/-- … -/`)** attach to top-level declarations as needed (they
appear on hover in VS Code). Module doc comments `/-! … -/` are currently unused.

## Differences from Rocq (selected)

See [COMMENTARY.md](COMMENTARY.md) for the full discussion. Highlights:

* **Aborting:** unnamed `example … := sorry` replaces Rocq's `Abort`.
* **`inversion`:** `cases`/inversion in Lean often needs an explicit
  generalization the Rocq version did not (e.g. inverting `n ≤ 0` needs
  `generalizing` because `≤`'s `succ` constructor won't unify with `0`).
* **Classical logic** is more pervasive in Lean; the `Logic` chapter is being
  rewritten to teach idiomatic classical style (`classical` vs `open Classical`)
  rather than transplant Rocq's treatment.
* **`++` associativity** differs: Lean's `app_assoc` is
  `l ++ m ++ n = l ++ (m ++ n)` (Rocq groups the other way).

## Working conventions

* `main` must always build; never commit directly to `main` — branch, PR, let CI
  (`lake build`) go green, then merge. Don't merge a red PR.
* For changes confined to this repo, review happens at commit/PR time via git;
  proceed through project-local edits, builds, and regeneration without
  per-action confirmation.
