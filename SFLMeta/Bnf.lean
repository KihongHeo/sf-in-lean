import VersoManual

open Lean Elab
open Verso ArgParse Doc Elab Genre.Manual
open Verso.Output Verso.Output.Html
open Verso.Doc.Html

namespace SFLMeta

/-- A token in a BNF production right-hand side. -/
inductive BnfToken where
  /-- A reference to a non-terminal (the same kind of thing the LHS defines), e.g. `T` or `t`.
  Written as a plain identifier in the source. -/
  | nonterm (name : String)
  /-- A schematic variable standing for an arbitrary object-language identifier, e.g. `x` in
  `λ x : T , t`. Written with a leading underscore in the source (`_x` → displayed as `x`). -/
  | «meta» (name : String)
  /-- A literal terminal of the object language, written as a string in the source. -/
  | lit (literal : String)
deriving Repr, Inhabited, BEq, ToJson, FromJson

/-- A single BNF production: `lhs ::= alts[0] | alts[1] | ...`. -/
structure BnfProduction where
  /-- The non-terminal being defined. -/
  lhs : String
  /-- The right-hand-side alternatives, each a sequence of tokens. -/
  alts : Array (Array BnfToken)
deriving Repr, Inhabited, BEq, ToJson, FromJson

/-- A BNF grammar: a sequence of productions in source order. -/
structure BNF where
  /-- The productions. -/
  productions : Array BnfProduction
deriving Repr, Inhabited, BEq, ToJson, FromJson

namespace Bnf

/-! ## Surface syntax

A `bnf%` term and a ` ```bnf ` code block share the same grammar. Productions end
with `;`; alternatives within a production are separated by `|`; a token is either
an identifier (metavariable) or a string literal (terminal). -/

/-- A token of the BNF surface syntax. -/
declare_syntax_cat bnfTok
/-- An identifier is a metavariable token. -/
syntax ident : bnfTok
/-- A string literal is a terminal token. -/
syntax str : bnfTok

/-- One alternative of a BNF production. -/
declare_syntax_cat bnfAlt
/-- An alternative is a non-empty sequence of tokens. -/
syntax bnfTok+ : bnfAlt

/-- A single production. -/
declare_syntax_cat bnfProd
/-- A production: `lhs ::= alt | alt | … ;`. The trailing `;` separates productions. -/
syntax ident "::=" bnfAlt ("|" bnfAlt)* ";" : bnfProd

/-- A sequence of productions: the body of a `bnf%` or ` ```bnf ` block. -/
declare_syntax_cat bnfBody
/-- A body is zero or more productions. -/
syntax bnfProd* : bnfBody

/-- A term-level BNF literal: elaborates to a `SFLMeta.BNF` value. -/
syntax (name := bnfTerm) "bnf%" bnfBody "end" : term

/-! ## Macro: parsed syntax → term -/

/-- Translate a parsed `bnfTok` to term syntax producing a `BnfToken`.

An identifier with a leading underscore is a schematic metavariable (the underscore is
stripped); any other identifier is a non-terminal reference. -/
def tokToTerm (stx : TSyntax `bnfTok) : MacroM (TSyntax `term) :=
  match stx with
  | `(bnfTok| $i:ident) =>
    let name := i.getId.toString
    if name.startsWith "_" then
      let s := Syntax.mkStrLit (name.drop 1).toString
      `(SFLMeta.BnfToken.meta $s)
    else
      let s := Syntax.mkStrLit name
      `(SFLMeta.BnfToken.nonterm $s)
  | `(bnfTok| $s:str) =>
    `(SFLMeta.BnfToken.lit $s)
  | _ => Macro.throwUnsupported

/-- Translate a parsed `bnfAlt` to term syntax producing an `Array BnfToken`. -/
def altToTerm (stx : TSyntax `bnfAlt) : MacroM (TSyntax `term) := do
  let `(bnfAlt| $toks:bnfTok*) := stx | Macro.throwUnsupported
  let tokTerms ← toks.mapM tokToTerm
  `(#[$tokTerms,*])

/-- Translate a parsed `bnfProd` to term syntax producing a `BnfProduction`. -/
def prodToTerm (stx : TSyntax `bnfProd) : MacroM (TSyntax `term) := do
  let `(bnfProd| $lhs:ident ::= $first:bnfAlt $[| $rest:bnfAlt]* ;) := stx
    | Macro.throwUnsupported
  let lhsStr := Syntax.mkStrLit lhs.getId.toString
  let altTerms ← (#[first] ++ rest).mapM altToTerm
  `(({ lhs := $lhsStr, alts := #[$altTerms,*] } : SFLMeta.BnfProduction))

macro_rules
  | `(bnf% $body:bnfBody end) => do
    let `(bnfBody| $[$prods:bnfProd]*) := body | Macro.throwUnsupported
    let prodTerms ← prods.mapM prodToTerm
    `(({ productions := #[$prodTerms,*] } : SFLMeta.BNF))

/-! ## Runtime parser for the code-block body -/

/-- Translate a parsed `bnfTok` syntax to a `BnfToken` value.

Idents starting with `_` are schematic metavariables (the underscore is stripped); other
idents are non-terminal references. -/
def tokOfSyntax (stx : TSyntax `bnfTok) : Except String BnfToken :=
  match stx with
  | `(bnfTok| $i:ident) =>
    let name := i.getId.toString
    if name.startsWith "_" then .ok (.meta (name.drop 1).toString)
    else .ok (.nonterm name)
  | `(bnfTok| $s:str)   => .ok (.lit s.getString)
  | _ => .error s!"unrecognized bnfTok"

/-- Translate a parsed `bnfAlt` to an `Array BnfToken`. -/
def altOfSyntax (stx : TSyntax `bnfAlt) : Except String (Array BnfToken) := do
  let `(bnfAlt| $toks:bnfTok*) := stx | .error "expected bnfAlt"
  toks.mapM tokOfSyntax

/-- Translate a parsed `bnfProd` to a `BnfProduction`. -/
def prodOfSyntax (stx : TSyntax `bnfProd) : Except String BnfProduction := do
  let `(bnfProd| $lhs:ident ::= $first:bnfAlt $[| $rest:bnfAlt]* ;) := stx
    | .error "expected bnfProd"
  let alts ← (#[first] ++ rest).mapM altOfSyntax
  pure { lhs := lhs.getId.toString, alts }

/-- Translate a parsed `bnfBody` to a `BNF`. -/
def bnfOfSyntax (stx : TSyntax `bnfBody) : Except String BNF := do
  let `(bnfBody| $[$prods:bnfProd]*) := stx | .error "expected bnfBody"
  let productions ← prods.mapM prodOfSyntax
  pure { productions }

/--
Parse a BNF source string (the body of a ` ```bnf ` block) into a `BNF`.
Surfaces parser and translation errors via `throwError`.
-/
def parseString (src : String) : DocElabM BNF := do
  let env ← getEnv
  match Lean.Parser.runParserCategory env `bnfBody src with
  | .error e => throwError "BNF parse error: {e}"
  | .ok stx =>
    match bnfOfSyntax ⟨stx⟩ with
    | .ok bnf => pure bnf
    | .error e => throwError "BNF: {e}"

/-! ## HTML rendering -/

/-- Render a single token as inline HTML. -/
def tokToHtml : BnfToken → Html
  | .nonterm s => {{ <span class="bnf-nt">{{s}}</span> }}
  | .meta    s => {{ <span class="bnf-mv">{{s}}</span> }}
  | .lit     s => {{ <span class="bnf-kw">{{s}}</span> }}

/-- Render a single alternative (sequence of tokens) as inline HTML. -/
def altToHtml (alt : Array BnfToken) : Html :=
  Html.seq <| alt.foldl (init := #[]) fun acc t =>
    if acc.isEmpty then #[tokToHtml t]
    else acc.push (Html.text false " ") |>.push (tokToHtml t)

/-- Render a full BNF grammar as a structured HTML table. The LHS of each production is
rendered with the same `.bnf-nt` styling as a non-terminal reference on the RHS so that the
same name looks the same wherever it appears. -/
def toHtmlImpl (b : BNF) : Html :=
  let rows : Array Html := b.productions.flatMap fun p =>
    p.alts.mapIdx fun i alt =>
      let lhsCell : Html :=
        if i = 0 then {{ <td class="bnf-lhs"><span class="bnf-nt">{{p.lhs}}</span></td> }}
        else {{ <td class="bnf-lhs">{{" "}}</td> }}
      let sep : String := if i = 0 then "::=" else "|"
      {{ <tr>
           {{lhsCell}}
           <td class="bnf-sep">{{sep}}</td>
           <td class="bnf-alt">{{altToHtml alt}}</td>
         </tr> }}
  {{ <table class="bnf">{{Html.seq rows}}</table> }}

/-! ## TeX rendering -/

/-- Render a single token as a TeX fragment. -/
def tokToTeX : BnfToken → Verso.Output.TeX
  | .nonterm s => .raw s!"\\mathit\{{s}}"
  | .meta    s => .raw s!"\\mathit\{{s}}"
  | .lit     s => .raw s!"\\textsf\{{s}}"

/-- Render an alternative as a TeX fragment, with `~` separators between tokens. -/
def altToTeX (alt : Array BnfToken) : Verso.Output.TeX :=
  Verso.Output.TeX.seq <| alt.foldl (init := #[]) fun acc t =>
    if acc.isEmpty then #[tokToTeX t]
    else acc.push (.raw "~") |>.push (tokToTeX t)

/-- Render a full BNF grammar as a LaTeX `tabular` environment. -/
def toTeXImpl (b : BNF) : Verso.Output.TeX :=
  let rows : Array Verso.Output.TeX := b.productions.flatMap fun p =>
    p.alts.mapIdx fun i alt =>
      let lhsCell : Verso.Output.TeX :=
        if i = 0 then .raw s!"\\mathit\{{p.lhs}}" else .empty
      let sep : Verso.Output.TeX :=
        if i = 0 then .raw "::=" else .raw "$\\mid$"
      .seq #[lhsCell, .raw " & ", sep, .raw " & ", altToTeX alt, .raw " \\\\\n"]
  .seq #[.raw "\\begin{tabular}{lll}\n", .seq rows, .raw "\\end{tabular}\n"]

end Bnf

/-! ## Block extension and code block -/

block_extension Block.bnf (json : String) (source : String) where
  data := Json.arr #[.str json, .str source]
  traverse _ _ _ := pure none
  toHtml :=
    open Verso.Output.Html in
    some <| fun _ _ _ data _ => do
      match data with
      | .arr #[.str jsonStr, .str _] =>
        match Json.parse jsonStr >>= fromJson? with
        | .ok (b : BNF) => pure (Bnf.toHtmlImpl b)
        | .error e =>
          Verso.reportError s!"BNF deserialization failed: {e}"
          pure .empty
      | _ =>
        Verso.reportError "BNF: malformed data"
        pure .empty
  toTeX :=
    open Verso.Output.TeX in
    some <| fun _ _ _ data _ => do
      match data with
      | .arr #[.str jsonStr, .str _] =>
        match Json.parse jsonStr >>= fromJson? with
        | .ok (b : BNF) => pure (Bnf.toTeXImpl b)
        | .error e =>
          Verso.reportError s!"BNF deserialization failed: {e}"
          pure .empty
      | _ =>
        Verso.reportError "BNF: malformed data"
        pure .empty
  extraCss := [
r##"
table.bnf {
  margin: 1em auto;
  border-collapse: collapse;
  font-family: var(--verso-code-font-family, monospace);
}
table.bnf td {
  padding: 0.15em 0.5em;
  vertical-align: baseline;
}
table.bnf td.bnf-lhs { text-align: right; }
table.bnf td.bnf-sep { text-align: center; }
table.bnf td.bnf-alt { text-align: left; }
table.bnf .bnf-nt  { font-style: italic; }
table.bnf .bnf-mv  {
  font-style: italic;
  text-decoration: underline;
  text-decoration-thickness: 0.5px;
  text-underline-offset: 0.18em;
}
table.bnf .bnf-kw  { font-weight: 600; font-family: var(--verso-code-font-family, monospace); }
"##
  ]

/-- A ` ```bnf ` code block: parses its body as a BNF grammar and stores both the
parsed structure (for HTML/TeX rendering) and the original source. -/
@[code_block]
def bnf : CodeBlockExpanderOf Unit
  | (), str => do
    let src := str.getString
    let bnfVal ← Bnf.parseString src
    let json := (toJson bnfVal).compress
    ``(Verso.Doc.Block.other
        (SFLMeta.Block.bnf $(quote json) $(quote src))
        #[Verso.Doc.Block.code $(quote src)])

end SFLMeta
