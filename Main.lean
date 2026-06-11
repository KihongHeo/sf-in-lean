import VersoManual
import LF
import SFLMeta.Theme

open Verso.Genre Manual

def config : RenderConfig where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCss := {SFLMeta.sfTheme}
  --extraFiles := [("assets", "assets")]

def main := manualMain (%doc LF) (config := config)
  (extraSteps := [SFLMeta.emitSaved])
