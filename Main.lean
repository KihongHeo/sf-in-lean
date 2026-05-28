import VersoManual
import LF
import LF.Meta.Theme

open Verso.Genre Manual

def config : Config where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCss := {LF.Meta.sfTheme}
  --extraFiles := [("assets", "assets")]

def main := manualMain (%doc LF) (config := { config with })
  (extraSteps := [LF.Meta.emitSaved])
