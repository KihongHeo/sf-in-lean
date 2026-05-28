import VersoManual
import LF.Meta.Bnf
import LF.Meta.Ignore
import LF.Meta.Exercise
import LF.Meta.Details
import Std.Data.HashMap
import SubVerso.Highlighting

open Lean Elab
open Verso.Genre Manual
open Verso.Doc Elab
open Verso.ArgParse
open Std (HashMap)
open SubVerso.Highlighting
open Verso.Genre.Manual.InlineLean.Scopes (getScopes setScopes)

namespace PLF.Meta

block_extension Block.devcomment where
  data := Json.null
  traverse _ _ _ := pure none
  toHtml := some fun _ _ _ _ _ => pure .empty
  toTeX := none

/-! ## `:::diagramWithAlt` directive -/

/--
A `:::devcomment` directive is a noop for inline developer comments. -/
@[directive]
def dev : DirectiveExpanderOf Unit
  | (), _ => ``(Verso.Doc.Block.other PLF.Meta.Block.devcomment #[])
