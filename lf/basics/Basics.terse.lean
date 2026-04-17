/-
  Basics: Functional Programming in Lean
-/


/- In Lean, we can build practically everything from first principles... -/


/- A datatype definition: -/


inductive Day : Type where
  | monday
  | tuesday
  | wednesday
  | thursday
  | friday
  | saturday
  | sunday

/- *** -/
/- A function on days: -/

def nextWorkingDay (d : Day) : Day :=
  match d with
  | .monday    => .tuesday
  | .tuesday   => .wednesday
  | .wednesday => .thursday
  | .thursday  => .friday
  | .friday    => .monday
  | .saturday  => .monday
  | .sunday    => .monday


/- *** -/
/- Evaluation: -/

#eval nextWorkingDay Day.friday
-- ==> Day.monday

#eval nextWorkingDay (nextWorkingDay Day.saturday)
-- ==> Day.tuesday


/-
  Second, we can record what we _expect_ the result to be in the
  form of a Lean "example":
-/

-- test_next_working_day
example : nextWorkingDay (nextWorkingDay Day.saturday) = Day.tuesday := by
  rfl


/-
  Third, we can ask Lean to _compile_ our definitions to efficient
  native code.  Lean compiles to C, which is then compiled to machine
  code by a standard C compiler.  This facility is very useful, since
  it gives us a path from proved-correct algorithms written in Lean to
  efficient executables.

  Indeed, this is one of the main uses for which Lean was developed.
  We'll come back to this topic in later chapters.
-/


/- Another familiar enumerated type: -/

/-
  We define our own `MyBool` to teach the concept of building from
  scratch; later we'll switch to Lean's built-in `Bool`.
-/


section

inductive MyBool : Type where
  | true
  | false
open MyBool

/- Booleans are also available in Lean's standard library, but in this course we'll define everything from scratch, just to see how it's done. -/
/- *** -/

def notb (b : MyBool) : MyBool :=
  match b with
  | .true => false
  | .false => true

/- *** -/

def andb (b1 : MyBool) (b2 : MyBool) : MyBool :=
  match b1 with
  | .true => b2
  | .false => false

def orb (b1 : MyBool) (b2 : MyBool) : MyBool :=
  match b1 with
  | .true => true
  | .false => b2


/- Note the syntax for defining multi-argument functions (`andb` and `orb`). -/
/- *** -/

-- test_orb1
example : orb .true  .false = .true  := by rfl
-- test_orb2
example : orb .false .false = .false := by rfl
-- test_orb3
example : orb .false .true  = .true  := by rfl
-- test_orb4
example : orb .true  .true  = .true  := by rfl

/-
  We can define new symbolic notations for existing definitions.
  Because Lean already defines these for the built-in `Bool`,
  we restrict ours locally to a section.
-/

section
local prefix:40 (priority := high) "!" => notb
local infixl:35 (priority := high) " && " => andb
local infixl:30 (priority := high) " || " => orb

-- test_orb5
example : (.false || .false || .true) = .true := by rfl

-- test_orb6
example : (! .false) = .true := by rfl
end

/- *** -/

def nandb (b1 : MyBool) (b2 : MyBool) : MyBool
  := sorry

-- test_nandb1
example : nandb .true .false  = .true  := by sorry  -- ADMITTED
-- test_nandb2
example : nandb .false .false = .true  := by sorry  -- ADMITTED
-- test_nandb3
example : nandb .false .true  = .true  := by sorry  -- ADMITTED
-- test_nandb4
example : nandb .true .true   = .false := by sorry  -- ADMITTED
-- GRADE_THEOREM 1: nandb_test4
-- []


def andb3 (b1 : MyBool) (b2 : MyBool) (b3 : MyBool) : MyBool
  := sorry

-- test_andb31
example : andb3 .true .true .true  = .true  := by sorry  -- ADMITTED
-- test_andb32
example : andb3 .false .true .true = .false := by sorry  -- ADMITTED
-- test_andb33
example : andb3 .true .false .true = .false := by sorry  -- ADMITTED
-- test_andb34
example : andb3 .true .true .false = .false := by sorry  -- ADMITTED
-- GRADE_THEOREM 1: andb3_test4
-- []


  /-
    RADDTION
  -/

/- *** -/

def myBoolToBool (b : MyBool) : Bool :=
  match b with
  | .true => true
  | .false => false


def boolToMyBool (b : Bool) : MyBool :=
  bif b then true else false

end


#check true
-- ===> true : Bool


#check (true : Bool)
#check (not true : Bool)


#check not
-- ===> not : Bool → Bool


/- A more interesting type definition: -/

inductive RGB : Type where
  | red
  | green
  | blue

inductive Color : Type where
  | black
  | white
  | primary (p : RGB)

/-
  Let's look at this in a little more detail.

  An `inductive` definition does two things:

  - It introduces a set of new _constructors_. E.g., `RGB.red`,
    `Color.primary`, `true`, `false`, `Day.monday`, etc. are constructors.

  - It groups them into a new named type, like `Bool`, `RGB`, or
    `Color`.

  _Constructor expressions_ are formed by applying a constructor
  to zero or more other constructors or constructor expressions,
  obeying the declared number and types of the constructor arguments.
  E.g., these are valid constructor expressions...
      - `RGB.red`
      - `true`
      - `Color.primary RGB.red`
      - etc.
  ...but these are not:
      - `RGB.red Color.primary`
      - `true RGB.red`
      - `Color.primary (Color.primary RGB.red)`
      - etc.
-/

/- *** -/

/-
  We can define functions on colors using pattern matching just as
  we did for `Day` and `Bool`.
-/

def monochrome (c : Color) : Bool :=
  match c with
  | .black => true
  | .white => true
  | .primary _ => false

/-
  Since the `primary` constructor takes an argument, a pattern
  matching `primary` should include either a variable, as we just
  did (note that we can choose its name freely), or a constant of
  appropriate type (as below).
-/

def isRed (c : Color) : Bool :=
  match c with
  | .black => false
  | .white => false
  | .primary .red => true
  | .primary _ => false

/-
  The pattern `Color.primary _` here is shorthand for "the constructor
  `primary` applied to any `RGB` constructor except `red`."
-/


/- `namespace` declarations create separate namespaces. -/

namespace Playground
def myFoo : RGB := RGB.blue
end Playground

def myFoo : Bool := true

#check Playground.myFoo  -- RGB
#check myFoo             -- Bool


namespace RGB
def myBlue : RGB := blue
end RGB

def RGB.myOtherBlue : RGB := myBlue

/-
  #check myBlue -- unknown identifier
-/
#check RGB.myBlue      -- RGB
#check RGB.myOtherBlue -- RGB

/- `section` declarations delimit the scope of `open` and `local`. -/

section
open Playground
local postfix:40 "′" => Color.primary

#check myFoo        -- RGB
#check _root_.myFoo -- Bool
#check RGB.blue′    -- Color
end

#check myFoo         -- Bool
/-
  #check RGB.blue′  -- fails to parse
-/


namespace TuplePlayground


/- A nybble is half a byte -- four bits. -/

inductive Bit : Type where
  | b1
  | b0

inductive Nybble : Type where
  | bits (x0 x1 x2 x3 : Bit)

#check (.bits .b1 .b0 .b1 .b0 : Nybble)


/- *** -/
/- We can deconstruct a nybble by pattern-matching. -/

def allZero (nb : Nybble) : Bool :=
  match nb with
  | .bits .b0 .b0 .b0 .b0 => true
  | .bits _   _   _   _   => false

/-
  (The underscore `_` here is a _wildcard pattern_, which avoids
  inventing variable names that will not be used.)
-/

#eval allZero (.bits .b1 .b0 .b1 .b0)
-- ===> false
#eval allZero (.bits .b0 .b0 .b0 .b0)
-- ===> true

end TuplePlayground


namespace NatPlayground


/- For simplicity in proofs, we choose unary representation. -/

inductive Nat : Type where
  | zero
  | succ (n : Nat)

/-
  With this definition, 0 is represented by `zero`, 1 by `succ zero`,
  2 by `succ (succ zero)`, and so on.
-/

/- *** -/
/-
  Critical point: this just defines a _representation_ of
  numbers -- a unary notation for writing them down.
-/

inductive OtherNat : Type where
  | stop
  | tick (foo : OtherNat)

/-
  This is the same _representation_ of numbers as `Nat`, but with different
  (sillier!) constructor names.
-/

/-
  The _interpretation_ of these representations arises from how we use them to
  compute.
-/

def pred (n : Nat) : Nat :=
  match n with
  | .zero => .zero
  | .succ n' => n'

end NatPlayground

/- *** -/

/-
  Because natural numbers are such a pervasive kind of data,
  Lean provides built-in support for them: ordinary decimal
  numerals can be used as a shorthand, and Lean's `Nat` type uses
  the constructors `Nat.zero` and `Nat.succ`.
-/


example : .succ (.succ (.succ (.succ .zero))) = 4 := by rfl

def minustwo (n : Nat) : Nat :=
  match n with
  | 0                => 0
  | 1                => 0
  | .succ (.succ n') => n'

#eval minustwo 4
-- ===> 2

#check Nat.succ  -- Nat → Nat
#check Nat.pred  -- Nat → Nat
#check minustwo  -- Nat → Nat


/- *** -/
/- Recursive functions: -/

def even (n : Nat) : Bool :=
  match n with
  | 0                => true
  | 1                => false
  | .succ (.succ n') => even n'

/- *** -/
/-
  We could define `odd` by a similar recursive declaration, but
  here is a simpler way:
-/

def odd (n : Nat) : Bool :=
  not (even n)

-- test_odd1
example : odd 1 = true  := by rfl
-- test_odd2
example : odd 4 = false := by rfl

/- *** -/
/- A multi-argument recursive function. -/

def add (n : Nat) (m : Nat) : Nat :=
  match m with
  | 0 => n
  | .succ m' => .succ (add n m')


#eval add 3 2
-- ===> 5

--    ==> `succ (add (succ (succ (succ 0))) (succ 0))`
--    ==> `succ (succ (add (succ (succ (succ 0))) 0))`
--    ==> `succ (succ (succ (add (succ 0))))`

/- *** -/


def mul (n m : Nat) : Nat :=
  match m with
  | 0 => 0
  | .succ m' => (mul n m') + n

-- test_mult1
example : mul 3 3 = 9 := by rfl

/- *** -/
/-
  We can pattern-match two values at the same time:
-/

def sub (n m : Nat) : Nat :=
  match n, m with
  | 0,        _        => 0
  | .succ _,  0        => n
  | .succ n', .succ m' => sub n' m'

/-
  Now that we've seen how natural numbers are built from `Nat.zero`
  and `Nat.succ`, we can take further advantage of Lean's notation: the
  pattern `n + 1` is syntactic sugar for `Nat.succ n`, `n + 2` is
  syntactic sugar for `Nat.succ (Nat.succ n)`, and so on.
  We'll use this more concise style from now on.
-/

def pow (base power : Nat) : Nat :=
  match power with
  | 0 => 1
  | p + 1 => mul base (pow base p)


def factorial (n : Nat) : Nat
  := sorry

-- test_factorial1
example : factorial 3 = 6         := by sorry  -- ADMITTED
-- test_factorial2
example : factorial 5 = 10 * 12   := by sorry  -- ADMITTED
-- GRADE_THEOREM 1: factorial_test2
-- []

/- *** -/
/-
  Lean already provides `+`, `-`, `*` for `Nat`, so we don't need to
  define our own notation.
-/


instance instSub : Sub Nat where sub := sub
instance instMul : Mul Nat where mul := mul
instance instPow : Pow Nat Nat where pow := pow


#check (0 + 1 + 1 : Nat)
#check (4 - 3 - 2 : Nat)
#check (2 * 3 * 4 : Nat)
#check (1 ^ 2 ^ 2 : Nat)

/- *** -/
/-
  When we say that Lean comes with almost nothing built-in, we really
  mean it: even testing equality is a user-defined operation!

  Here is a function `beq` that tests natural numbers for
  equality, yielding a boolean.
-/

def beq (n m : Nat) : Bool :=
  match n with
  | 0 => match m with
         | 0 => true
         | _ + 1 => false
  | n' + 1 => match m with
              | 0 => false
              | m' + 1 => beq n' m'

/- *** -/
/-
  Similarly, the `leb` function tests whether its first argument is
  less than or equal to its second argument, yielding a boolean.
-/

def leb (n m : Nat) : Bool :=
  match n with
  | 0 => true
  | n' + 1 =>
      match m with
      | 0 => false
      | m' + 1 => leb n' m'

-- test_leb1
example : leb 2 2 = true  := by rfl
-- test_leb2
example : leb 2 4 = true  := by rfl
-- test_leb3
example : leb 4 2 = false := by rfl

/- *** -/
/-
  We'll be using these (especially `beq`) a lot, so let's give
  them infix notations.
-/


instance : BEq Nat where
  beq := beq

infix:65 "<=?" => leb

/-
  test_leb3'
-/
example : 4 <=? 2 = false := by rfl


def ltb (n m : Nat) : Bool
  := sorry

infix:65 "<?" => ltb

-- test_ltb1
example : 2 <? 2 = false := by sorry  -- ADMITTED
-- test_ltb2
example : 2 <? 4 = true  := by sorry  -- ADMITTED
-- test_ltb3
example : 4 <? 2 = false := by sorry  -- ADMITTED
-- GRADE_THEOREM 1: ltb_test3
-- []


/- A specific fact about natural numbers: -/
/-
  plus_1_1
-/
example : 1 + 1 = 2 := by rfl

/- Another specific fact about natural numbers: -/
theorem add_zero_one : 1 = 0 + 1 := by rfl


/- A general property of natural numbers: -/

/-
  Note: Because Lean's addition recurses on the second argument,
  `n + 0` reduces to `n` by definition.
  `n + 0` reduces to `n` by definition.
-/

theorem add_zero : ∀ n : Nat, n + 0 = n := by
  intro n; rfl


/- *** -/


theorem add_succ : ∀ n m : Nat, n + (m + 1) = (n + m) + 1 := by
  intro n m; rfl

theorem mul_zero : ∀ n : Nat, n * 0 = 0 := by
  intro n; rfl

theorem mul_succ : ∀ n m : Nat, n * (m + 1) = n * m + n := by
  intro n m; rfl


#check Nat.sub_zero

theorem sub_zero n : 0 - n = 0 := by rfl
theorem succ_sub_zero n : (n + 1) - 0 = n + 1 := by rfl
theorem succ_sub_succ n m : (n + 1) - (m + 1) = n - m := by rfl

theorem pow_zero n : n ^ 0 = 1 := by rfl
theorem pow_succ (n m : Nat) : n ^ (m + 1) = n * (n ^ m) := by rfl


theorem beq_succ : ∀ n m : Nat, (n + 1 == m + 1) = (n == m) := by
  intro n m; rfl


theorem plus_id_example : ∀ n m : Nat,
    n = m →
    n + n = m + m := by
  intro n m
  intro h
  rewrite [h]
  rfl

/- The `intro` tactic names the hypotheses as they are moved to the context.  The `rewrite` tactic rewrites using an equality. -/

/-
  TODO: Move this
-/


theorem plus_id_exercise : ∀ n m o : Nat,
    n = m → m = o → n + m = m + o := by
  sorry
-- GRADE_THEOREM 1: plus_id_exercise
-- []


/- *** -/

/-
  The `#check` command can also be used to examine the statements of
  previously declared lemmas and theorems.
-/

#check mul_zero  -- ∀ (n : Nat), n * 0 = 0
#check mul_succ  -- ∀ (n m : Nat), n * Nat.succ m = n + n * m

/- *** -/
/-
  We can use the `rewrite` tactic with a previously proved theorem
  instead of a hypothesis from the context.
-/

theorem add_mul_zero : ∀ p q : Nat,
    (p * 0) + (q * 0) = 0 := by
  intro p q
  rewrite [mul_zero, mul_zero, add_zero]
  rfl


/- Sometimes simple calculation and rewriting are not enough... -/
example : ∀ n : Nat,
    (n + 1 == 0) = false := by
  intro n
  /-
    `rfl` doesn't work here because `n` is unknown
  -/
  sorry


/- We can use `cases` to perform case analysis: -/

theorem add_one_neb_zero : ∀ n : Nat,
    (n + 1 == 0) = false := by
  intro n
  cases n
  case zero => rfl
  case succ n' => rfl


/- *** -/
/- Another example, using booleans: -/

theorem notb_involutive : ∀ b : Bool,
    (!!b) = b := by
  intro b
  cases b
  case true => rfl
  case false => rfl

/- *** -/
/- We can have nested case analysis: -/

theorem andb_commutative : ∀ b c : Bool,
    (b && c) = (c && b) := by
  intro b c
  cases b
  case true =>
    cases c
    case true => rfl
    case false => rfl
  case false =>
    cases c
    case true => rfl
    case false => rfl

theorem andb3_exchange : ∀ b c d : Bool,
    ((b && c) && d) = ((b && d) && c) := by
  intro b c d
  cases b
  case false =>
    cases c
    case true =>
      cases d
      case false => rfl
      case true => rfl
    case false =>
      cases d
      case false => rfl
      case true => rfl
  case true =>
    cases c
    case true =>
      cases d
      case false => rfl
      case true => rfl
    case false =>
      cases d
      case false => rfl
      case true => rfl

/- As you can see, this can become very verbose.
  We will introduce some tactics for writing shorter proofs
  by case analysis in `Tactics.lean`. -/

/-
  ** New Tactics: `dsimp`, and `exact`.

  Some more tactics will be useful for the exercises ahead.

  The `dsimp` tactic ("definitionally simplify") applies known facts
  and definitions to simplify the goal.  You can give it hints in
  square brackets: `dsimp [f]` tells it to unfold the definition
  of `f`.  You can also simplify a hypothesis `h` in the context
  by writing `dsimp [...] at h`. `dsimp` will also close goals by
  `rfl` when possible.

  The `exact` tactic closes a goal by providing an exact proof
  term.  For example, if `h : P` is in the context and the goal
  is `P`, then `exact h` closes the goal.  You can also
  transform `h` slightly — for instance, `exact h.symm` uses
  the symmetry of equality.
-/


theorem orb_false_true : ∀ b : Bool,
    (false || b) = true → b = true := by
  sorry
-- GRADE_THEOREM 2: orb_false_true
-- []

theorem zero_neb_add_one : ∀ n : Nat,
  (0 == n + 1) = false := by
  sorry
-- GRADE_THEOREM 1: zero_nbeq_plus_1
-- []


def plus' (n : Nat) (m : Nat) : Nat :=
  match n with
  | 0 => m
  | n' + 1 => (plus' n' m) + 1


-- []


theorem identity_fn_applied_twice : ∀ f : Bool → Bool,
    (∀ x : Bool, f x = x) →
    ∀ b : Bool, f (f b) = b := by
  sorry
-- GRADE_THEOREM 1: identity_fn_applied_twice
-- []


theorem negation_fn_applied_twice : ∀ f : Bool → Bool,
    (∀ x : Bool, f x = !x) →
    ∀ b : Bool, f (f b) = b := by
  intro f h b
  rewrite [h, h]
  cases b <;> rfl

-- []


theorem andb_eq_orb : ∀ b c : Bool,
    (b && c) = (b || c) →
  b = c := by
  sorry
-- GRADE_THEOREM 3: andb_eq_orb
-- []


namespace LateDays

inductive Letter : Type where
  | A | B | C | D | F

inductive Modifier : Type where
  | plus | natural | minus


structure Grade where
  letter : Letter
  modifier : Modifier

inductive Comparison : Type where
  | eq   -- "equal"
  | lt   -- "less than"
  | gt   -- "greater than"

open Letter Modifier Comparison

def letterComparison (l1 l2 : Letter) : Comparison :=
  match l1, l2 with
  | A, A => eq
  | A, _ => gt
  | B, A => lt
  | B, B => eq
  | B, _ => gt
  | C, A => lt
  | C, B => lt
  | C, C => eq
  | C, _ => gt
  | D, F => gt
  | D, D => eq
  | D, _ => lt
  | F, F => eq
  | F, _ => lt

example : letterComparison B A = lt := by rfl
example : letterComparison D D = eq := by rfl
example : letterComparison B F = gt := by rfl

theorem letterComparison_Eq : ∀ l : Letter,
    letterComparison l l = eq := by
  sorry
-- GRADE_THEOREM 1: letterComparison_Eq
-- []

def modifierComparison (m1 m2 : Modifier) : Comparison :=
  match m1, m2 with
  | plus, plus => eq
  | plus, _ => gt
  | natural, plus => lt
  | natural, natural => eq
  | natural, _ => gt
  | minus, minus => eq
  | minus, _ => lt


def gradeComparison (g1 g2 : Grade) : Comparison
  := sorry

-- test_grade_comparison1
example : gradeComparison ⟨A, minus⟩ ⟨B, plus⟩ = gt := by sorry  -- ADMITTED
-- test_grade_comparison2
example : gradeComparison ⟨A, minus⟩ ⟨A, plus⟩ = lt := by sorry  -- ADMITTED
-- test_grade_comparison3
example : gradeComparison ⟨F, plus⟩ ⟨F, plus⟩ = eq := by sorry  -- ADMITTED
-- test_grade_comparison4
example : gradeComparison ⟨B, minus⟩ ⟨C, plus⟩ = gt := by sorry  -- ADMITTED
-- GRADE_THEOREM 0.5: gradeComparison_test1
-- GRADE_THEOREM 0.5: gradeComparison_test2
-- GRADE_THEOREM 0.5: gradeComparison_test3
-- GRADE_THEOREM 0.5: gradeComparison_test4
-- []

def lowerLetter (l : Letter) : Letter :=
  match l with
  | A => B
  | B => C
  | C => D
  | D => F
  | F => F  -- Can't go lower than F!


theorem lowerLetter_F_is_F : lowerLetter F = F := by rfl

theorem lowerLetter_lowers : ∀ l : Letter,
    letterComparison F l = lt →
    letterComparison (lowerLetter l) l = lt := by
  sorry
-- GRADE_THEOREM 2: lowerLetter_lowers
-- []

def lowerGrade (g : Grade) : Grade
  := sorry

example : lowerGrade ⟨A, plus⟩ = ⟨A, natural⟩ := by sorry  -- ADMITTED
example : lowerGrade ⟨A, natural⟩ = ⟨A, minus⟩ := by sorry  -- ADMITTED
example : lowerGrade ⟨A, minus⟩ = ⟨B, plus⟩ := by sorry  -- ADMITTED
example : lowerGrade ⟨B, plus⟩ = ⟨B, natural⟩ := by sorry  -- ADMITTED
example : lowerGrade ⟨F, natural⟩ = ⟨F, minus⟩ := by sorry  -- ADMITTED
example : lowerGrade (lowerGrade ⟨B, minus⟩) = ⟨C, natural⟩ := by sorry  -- ADMITTED
example : lowerGrade (lowerGrade (lowerGrade ⟨B, minus⟩)) = ⟨C, minus⟩ := by sorry  -- ADMITTED

theorem lowerGrade_F_Minus : lowerGrade ⟨F, minus⟩ = ⟨F, minus⟩ := by sorry  -- ADMITTED

-- GRADE_THEOREM 0.25: lowerGrade_A_Plus
-- GRADE_THEOREM 0.25: lowerGrade_F_Minus
-- []

theorem lowerGrade_lowers : ∀ g : Grade,
    gradeComparison ⟨F, minus⟩ g = lt →
    gradeComparison (lowerGrade g) g = lt := by
  sorry
-- GRADE_THEOREM 3: lowerGrade_lowers
-- []

def applyLatePolicy (lateDays : Nat) (g : Grade) : Grade :=
  if lateDays <? 9 then g
  else if lateDays <? 17 then lowerGrade g
  else if lateDays <? 21 then lowerGrade (lowerGrade g)
  else lowerGrade (lowerGrade (lowerGrade g))

theorem applyLatePolicy_unfold : ∀ (lateDays : Nat) (g : Grade),
    applyLatePolicy lateDays g
    =
    (if lateDays <? 9 then g
     else if lateDays <? 17 then lowerGrade g
     else if lateDays <? 21 then lowerGrade (lowerGrade g)
     else lowerGrade (lowerGrade (lowerGrade g))) := by
  intro _ _; rfl

theorem no_penalty_for_mostly_on_time : ∀ (lateDays : Nat) (g : Grade),
    (lateDays <? 9 = true) →
    applyLatePolicy lateDays g = g := by
  sorry
-- GRADE_THEOREM 2: no_penalty_for_mostly_on_time
-- []

theorem grade_lowered_once : ∀ (lateDays : Nat) (g : Grade),
    (lateDays <? 9 = false) →
    (lateDays <? 17 = true) →
    applyLatePolicy lateDays g = lowerGrade g := by
  sorry
-- GRADE_THEOREM 2: grade_lowered_once
-- []

end LateDays


inductive Bin : Type where
  | z
  | b0 (n : Bin)
  | b1 (n : Bin)

def incr (m : Bin) : Bin
  := sorry

def binToNat (m : Bin) : Nat
  := sorry

-- test_bin_incr1
example : incr (.b1 .z) = .b0 (.b1 .z) := by sorry  -- ADMITTED
-- test_bin_incr2
example : incr (.b0 (.b1 .z)) = .b1 (.b1 .z) := by sorry  -- ADMITTED
-- test_bin_incr3
example : incr (.b1 (.b1 .z)) = .b0 (.b0 (.b1 .z)) := by sorry  -- ADMITTED
-- test_bin_incr4
example : binToNat (.b0 (.b1 .z)) = 2 := by sorry  -- ADMITTED
-- test_bin_incr5
example : binToNat (incr (.b1 .z)) = 1 + binToNat (.b1 .z) := by sorry  -- ADMITTED
-- test_bin_incr6
example : binToNat (incr (incr (.b1 .z))) = 2 + binToNat (.b1 .z) := by sorry  -- ADMITTED
-- test_bin_incr7
example : binToNat (.b0 (.b0 (.b0 (.b1 .z)))) = 8 := by sorry  -- ADMITTED

-- GRADE_THEOREM 0.5: incr_test1
-- GRADE_THEOREM 0.5: incr_test2
-- GRADE_THEOREM 0.5: incr_test3
-- GRADE_THEOREM 0.5: binToNat_test1
-- GRADE_THEOREM 0.5: binToNat_test2
-- GRADE_THEOREM 0.5: binToNat_test3
-- []

