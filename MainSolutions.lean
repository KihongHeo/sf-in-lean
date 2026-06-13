import VersoManual
import LF
import SFLMeta.Theme

open Verso.Genre Manual

/-- Solutions build: full prose, code with solutions shown. -/
def config : RenderConfig where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCss := {SFLMeta.sfTheme}
  destination := "_out/solutions"

def main (args : List String) : IO UInt32 := do
  SFLMeta.showSolutions.set true
  manualMain (%doc LF) (options := args) (config := config)
    (extraSteps := [SFLMeta.emitSavedSolutions])
