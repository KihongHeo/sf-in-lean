import VersoManual
import LF
import SFLMeta.Theme

open Verso.Genre Manual

/-- Terse (lecture/slides) build: terse prose, code with solutions elided. -/
def config : RenderConfig where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCss := {SFLMeta.sfTheme}
  draft := true          -- proxy for terse mode: kept true throughout traversal and rendering
  destination := "_out/terse"

def main (args : List String) : IO UInt32 := do
  SFLMeta.showSolutions.set false
  manualMain (%doc LF) (options := args) (config := config)
    (extraSteps := [SFLMeta.emitSavedTerse])
