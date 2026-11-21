#!/usr/bin/env bash
# Fetch upstream inputs for the FoMT native Android port (recomp-shaped).
# Pins (verified 2026-11-21):
#   gbarecomp  f23317ffc220587cba1b68620dfc53554fa5b22e (PolyForm Noncommercial 1.0.0)
#              — pinned SUBMODULE (see .gitmodules), updated here, NOT cloned
#              into third_party/.
#   fomt       b8471ae065744869f64283473ed68372f82321c9 (unlicensed decomp:
#              fetch-only, symbol source only, never vendored)
# Run from the repo root. fomt clones into third_party/ (gitignored).
# The user's ROM and BIOS are NEVER fetched by this script.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY="$ROOT/third_party"
mkdir -p "$THIRD_PARTY"

GBARECOMP_REV="f23317ffc220587cba1b68620dfc53554fa5b22e"
FOMT_REV="b8471ae065744869f64283473ed68372f82321c9"

# gbarecomp: pinned submodule — update it in place, then init its own
# submodules (incl. the SDL submodule the Android Gradle build needs).
git -C "$ROOT" submodule update --init --recursive
[ "$(git -C "$ROOT/gbarecomp" rev-parse HEAD)" = "$GBARECOMP_REV" ] \
  || { echo "ERROR: gbarecomp submodule is not at pinned rev $GBARECOMP_REV" >&2; exit 1; }
# The SDL submodule is required by the Android Gradle build; fail loudly here
# rather than halfway through a Gradle run.
test -d "$ROOT/gbarecomp/platform/android/third_party/SDL" \
  || { echo "ERROR: SDL submodule missing in gbarecomp checkout" >&2; exit 1; }

# fomt: fetch-at-build only (never vendored, never a submodule).
if [ ! -d "$THIRD_PARTY/fomt/.git" ]; then
  git clone https://github.com/StanHash/fomt.git "$THIRD_PARTY/fomt"
fi
git -C "$THIRD_PARTY/fomt" checkout "$FOMT_REV"

echo "gbarecomp: $(git -C "$ROOT/gbarecomp" rev-parse --short HEAD)"
echo "fomt:      $(git -C "$THIRD_PARTY/fomt" rev-parse --short HEAD)"
echo "Done. ROM and BIOS are still yours to supply (see README.md)."
