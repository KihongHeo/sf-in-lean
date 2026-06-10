import VersoManual
import LF
import SFLMeta.Theme

open Verso.Genre Manual

def config : Config where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCss := {SFLMeta.sfTheme}
  draft := true          -- proxy for terse mode: kept true throughout traversal and rendering
  destination := "_out/terse"

def main := manualMain (%doc LF) (config := config)
  (extraSteps := [SFLMeta.emitSavedTerse])
