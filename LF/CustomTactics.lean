module

public meta import Lean.Elab.Tactic.ElabTerm
public meta import Lean.Meta.Tactic.Generalize
public meta import Lean.Meta.Tactic.Cases
public meta import Lean.Meta.Tactic.Injection
public meta import Lean.Meta.Tactic.Contradiction

namespace Lean.Meta

/--
  This function is similar to `forallMetaTelescopeReducing`: Given `e` of the
  form `forall ..xs, A`, this combinator will create a new metavariable for
  each `x` in `xs` until it reaches an `x` whose type is defeq to `t`,
  and instantiate `A` with these, while also reducing `A` if needed.
  It uses `forallMetaTelescopeReducing`.

  This function returns a triple `(mvs, bis, out)` where
  - `mvs` is an array containing the new metavariables.
  - `bis` is an array containing the binder infos for the `mvs`.
  - `out` is `e` but instantiated with the `mvs`.

  Lifted from [https://github.com/leanprover-community/mathlib4/blob/master/Mathlib/Lean/Meta/Basic.lean#L41].
-/
meta def forallMetaTelescopeReducingUntilDefEq
    (e t : Expr) (kind : MetavarKind := MetavarKind.natural) :
    MetaM (Array Expr × Array BinderInfo × Expr) := do
  let (ms, bs, tp) ← forallMetaTelescopeReducing e (some 1) kind
  unless ms.size == 1 do
    if ms.size == 0 then throwError m!"Failed: {← ppExpr e} is not the type of a function."
    else throwError m!"Failed"
  let mut mvs := ms
  let mut bis := bs
  let mut out : Expr := tp
  while !(← isDefEq (← inferType mvs.toList.getLast!) t) do
    let (ms, bs, tp) ← forallMetaTelescopeReducing out (some 1) kind
    unless ms.size == 1 do
      throwError m!"Failed to find {← ppExpr t} as the type of a parameter of {← ppExpr e}."
    mvs := mvs ++ ms
    bis := bis ++ bs
    out := tp
  return (mvs, bis, out)

end Lean.Meta

namespace Lean.Elab.Tactic
open Meta Term

/--
  `apply t at i` uses forward reasoning with `t` at the hypothesis `i`.
  Explicitly, if `t : α₁ → ⋯ → αᵢ → ⋯ → αₙ` and `i` has type `αᵢ`, then this tactic adds
  metavariables/goals for any terms of `αⱼ` for `j = 1, …, i-1`,
  then replaces the type of `i` with `αᵢ₊₁ → ⋯ → αₙ` by applying those metavariables and the
  original `i`.

  Lifted from [https://github.com/leanprover-community/mathlib4/blob/master/Mathlib/Tactic/ApplyAt.lean].
-/
elab "apply " t:term " at " i:ident : tactic => withSynthesize <| withMainContext do
  let f ← elabTermForApply t
  let some ldecl := (← getLCtx).findFromUserName? i.getId
    | throwErrorAt i m!"Identifier {i} not found"
  let (mvs, bis, _) ← forallMetaTelescopeReducingUntilDefEq (← inferType f) ldecl.type
  for (m, b) in mvs.zip bis do
    if b.isInstImplicit && !(← m.mvarId!.isAssigned) then
      try m.mvarId!.inferInstance
      catch _ => continue
  let (_, mainGoal) ← (← getMainGoal).note ldecl.userName
    (← mkAppOptM' f (mvs.pop.push ldecl.toExpr |>.map some))
  let mainGoal ← mainGoal.tryClear ldecl.fvarId
  replaceMainGoal <| [mainGoal] ++ mvs.pop.toList.map (·.mvarId!)

/--
  `inversion t` generalizes nonvariable indices of the type of `t` before invoking `cases t`,
  then solves away contradictory generated goals.
-/
elab "inversion " targetName:term : tactic => withMainContext do
    let mvarId ← getMainGoal
    let target ← elabTerm targetName none
    let targetId := target.fvarId!
    let targetType ← inferType target
    let targetType ← whnf targetType
    let ⟨indName, args⟩ := targetType.getAppFnArgs
    match ← isInductive? indName with
    | some indVal =>
      let indices := args.drop indVal.numParams
      let nonvars := indices.filter (not ·.isFVar)
      let genargs : Array GeneralizeArg :=
        nonvars.map ({ expr := ·, xName? := some .anonymous, hName? := some .anonymous })
      let ⟨substs, _, mvarId⟩ ← mvarId.generalizeHyp genargs #[targetId]
      let .some newTarget := substs.map.find? targetId
        | throwTacticEx `inversion mvarId m!"failed to generalize argument"
      mvarId.withContext do
        let subgoals ← mvarId.cases newTarget.fvarId!
        let subgoals := subgoals.map (·.mvarId)
        let subgoals ← subgoals.filterM (not <$> ·.contradictionCore {})
        -- remove any subgoals closed by `injections`
        /- let subgoals ← subgoals.filterM (do
          match ← injections · with
          | InjectionsResult.solved => pure false
          | _ => pure true) -/
        replaceMainGoal $ subgoals.toList
    | none =>
      throwTacticEx `inversion mvarId
        m!"target is not an inductive type{indentExpr targetType}"

-- [https://github.com/leanprover-community/mathlib4/blob/master/Mathlib/Tactic/Lemma.lean]
-- [https://github.com/leanprover-community/batteries/blob/main/Batteries/Tactic/Lemma.lean]
/-- Synonym for `theorem`. -/
macro "lemma " thm:declId sig:declSig val:declVal : command => `(theorem $thm $sig $val)

end Lean.Elab.Tactic

example (f : Nat → Nat) (n : Nat) (le : f n ≤ 0) : f n = 0 := by
  -- cases le /- Dependent elimination failed: Failed to solve equation 0 = f n -/
  inversion le; rfl

example (H : Bool → Nat → False) (n : Nat) : False := by
  apply H at n; apply n; exact true

lemma doubleNegation : ∀ P, P → ¬ ¬ P := by
  intro P p np; exact (np p)
