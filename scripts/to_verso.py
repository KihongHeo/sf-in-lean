#!/usr/bin/env python3
"""First-pass conversion of a code-forward LF chapter to a Verso source file.

Strategy: keep the chapter as-is inside a single ```lean block, preceded by a
standard Verso header.  The result compiles and renders correctly; subsequent
manual passes will break it into proper docs-forward prose + code sections.

Usage (from the repo root):
    python3 scripts/to_verso.py LF/Basics.lean LF/BasicsVerso.lean

If the output file is omitted it defaults to the same stem with 'Verso' appended
in the same directory (e.g., LF/Basics.lean → LF/BasicsVerso.lean).
"""

import argparse
import pathlib
import re
import sys

# ---------------------------------------------------------------------------
# Verso header template
# ---------------------------------------------------------------------------
# Placeholders:
#   {title}   – the doc title (extracted from the source or given on command line)
#   {file}    – the htmlSplit file key (stem of the output file, e.g. "Basics")
HEADER_TEMPLATE = """\
import VersoManual
import VersoManual.InlineLean
import Illuminate
import SFLMeta.Bnf
import SFLMeta.Ignore
import SFLMeta.Save
import SFLMeta.Comment
import SFLMeta.Exercise
import SFLMeta.SlideBreak
import SFLMeta.Terse

open Verso.Genre Manual
open SFLMeta

open InlineLean hiding lean

set_option maxRecDepth 100000

noncomputable section

#doc (Manual) "{title}" =>
%%%
htmlSplit := .never
file := "{file}"
%%%

"""

FOOTER = "end\n"


def extract_title(src: str) -> str:
    """Pull the chapter title from the opening /- ... -/ block comment, if any.

    Looks for a block comment of the form:
        /-
          Chapter Title: ...
        -/
    or:
        /- Chapter Title -/

    Returns the trimmed first non-blank line of the comment body, or the
    fallback string "Chapter" when no title comment is found.
    """
    m = re.match(r"\s*/\-(.*?)-/", src, re.DOTALL)
    if m:
        body = m.group(1)
        lines = [l.strip() for l in body.splitlines() if l.strip()]
        if lines:
            # Strip leading '#' markers used in section headers
            title = lines[0].lstrip("#").strip()
            if title:
                return title
    return "Chapter"


def convert(src_text: str, title: str, file_key: str) -> str:
    """Return a Verso document that wraps *src_text* in a single lean block."""
    header = HEADER_TEMPLATE.format(title=title, file=file_key)
    # Ensure the source ends with exactly one newline before the closing fence
    body = src_text.rstrip("\n") + "\n"
    return header + "```lean\n" + body + "```\n" + FOOTER


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("src", metavar="SOURCE.lean",
                        help="code-forward chapter source (e.g. LF/Basics.lean)")
    parser.add_argument("dst", metavar="DEST.lean", nargs="?",
                        help="output Verso file (default: same dir, stem + 'Verso')")
    parser.add_argument("--title", default=None,
                        help="override the #doc title (auto-detected by default)")
    args = parser.parse_args()

    src_path = pathlib.Path(args.src)
    if not src_path.exists():
        sys.exit(f"Error: source file not found: {src_path}")

    if args.dst:
        dst_path = pathlib.Path(args.dst)
    else:
        dst_path = src_path.with_stem(src_path.stem + "Verso")

    src_text = src_path.read_text()
    title = args.title or extract_title(src_text)

    file_key = src_path.stem  # e.g. "Basics" — used as the HTML output filename
    result = convert(src_text, title, file_key)
    dst_path.write_text(result)
    print(f"Written {dst_path}  (title: {title!r}, file key: {file_key!r})")


if __name__ == "__main__":
    main()
