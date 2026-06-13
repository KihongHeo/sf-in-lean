# Makefile for sf-in-lean
#
# Each volume is built in three symmetric variants:
#   student    full prose, solutions elided   → _out/student/{html-multi,lean}
#   solutions  full prose, solutions shown    → _out/solutions/{html-multi,lean}
#   terse      lecture prose, solutions elided → _out/terse/{html-multi,lean}
#
# To add a new volume (e.g., PLF), define its targets with:
#   $(eval $(call VOLUME_template,plf,PLF))
# and add it to the `all` target below.  (Volume executables are expected to
# be named <slug>_student, <slug>_solutions, <slug>_terse in lakefile.toml.)

default: all

# ── Volume target template ────────────────────────────────────────────────────
# Usage: $(eval $(call VOLUME_template, slug, LibName))
#   slug      short name used in make targets and exe names, e.g. lf
#   LibName   Lake library name, e.g. LF
define VOLUME_template

.PHONY: $(1) $(1)-build $(1)-student $(1)-solutions $(1)-terse

$(1)-build:
	lake build $(2)

$(1)-student: $(1)-build
	lake exe $(1)_student

$(1)-solutions: $(1)-build
	lake exe $(1)_solutions

$(1)-terse: $(1)-build
	lake exe $(1)_terse

$(1): $(1)-student $(1)-solutions $(1)-terse

endef

# ── Volume definitions ────────────────────────────────────────────────────────

$(eval $(call VOLUME_template,lf,LF))

# ── Top-level targets ─────────────────────────────────────────────────────────

.PHONY: all serve clean

all: verso lf

serve: all
	python3 -m http.server 8000 -d _out/

clean:
	lake clean
	rm -rf _out/

# Temporary
verso: LF/BasicsVerso.lean

LF/BasicsVerso.lean: LF/Basics.lean scripts/to_verso.py
	 python3 scripts/to_verso.py $< $@
