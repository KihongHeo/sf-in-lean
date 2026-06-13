import VersoManual
import LF
import SFLMeta.Theme

open Verso.Genre Manual

/-- Student build: full prose, code with solutions elided. -/
def config : RenderConfig where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCss := {SFLMeta.sfTheme}
  destination := "_out/student"

def main (args : List String) : IO UInt32 := do
  SFLMeta.showSolutions.set false
  manualMain (%doc LF) (options := args) (config := config)
    (extraSteps := [SFLMeta.emitSavedStudent])
