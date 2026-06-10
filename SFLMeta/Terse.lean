import VersoManual

open Lean Elab
open Verso ArgParse Doc Elab Genre.Manual
open Verso.Output.Html

namespace SFLMeta

/-!
`Block.terse` wraps content that appears only in terse (lecture/live-coding)
builds. During traversal of a full build it is replaced with an empty block. -/
block_extension Block.terse where
  data := Json.null
  traverse _ _ _ := do
    if ← isDraft then
      return none            -- terse build: keep, recurse into children
    else
      return some (.concat #[])  -- full build: hide
  toHtml :=
    some fun _ goB _ _ contents =>
      Verso.Output.Html.seq <$> contents.mapM goB
  toTeX := none

/-!
`Block.full` wraps content that appears only in full (reading/HTML) builds.
During traversal of a terse build it is replaced with an empty block. -/
block_extension Block.full where
  data := Json.null
  traverse _ _ _ := do
    if ← isDraft then
      return some (.concat #[])  -- terse build: hide
    else
      return none            -- full build: keep, recurse into children
  toHtml :=
    some fun _ goB _ _ contents =>
      Verso.Output.Html.seq <$> contents.mapM goB
  toTeX := none

@[directive]
def terse : DirectiveExpanderOf Unit
  | (), contents => do
    let blocks ← contents.mapM elabBlock
    ``(Verso.Doc.Block.other SFLMeta.Block.terse #[$blocks,*])

@[directive]
def full : DirectiveExpanderOf Unit
  | (), contents => do
    let blocks ← contents.mapM elabBlock
    ``(Verso.Doc.Block.other SFLMeta.Block.full #[$blocks,*])

end SFLMeta
