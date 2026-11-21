#!/usr/bin/env bash
# regen.sh — regenerate the FoMT native build from the user's ROM.
# Adapted from Gitsnup/warioland4-recomp tools/regen.sh (5 steps).
# The ROM is the user's own dump; it is hash-gated, never shipped, and
# generated C++ is never committed (it is ROM-derived).
# Usage: tools/regen.sh --rom <path/to/fomt_usa.gba> [--jobs N] [--skip-decomp]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JOBS="$(nproc 2>/dev/null || echo 4)"
SKIP_DECOMP=0
ROM=""

while [ $# -gt 0 ]; do
  case "$1" in
    --rom) ROM="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --skip-decomp) SKIP_DECOMP=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[ -n "$ROM" ] || { echo "Usage: $0 --rom <fomt_usa.gba> [--jobs N] [--skip-decomp]" >&2; exit 1; }
[ -f "$ROM" ] || { echo "ERROR: ROM not found: $ROM" >&2; exit 1; }

# FoMT (USA) identity — SHA-1 per StanHash/fomt fomt.sha1; md5/crc32 to fill
# in from the first verified run and then hard-gate here.
ROM_SHA1="a2fc3574f0a65a4fcf7682fb274b9d7eebdef963"
ROM_MD5=""   # TODO: fill after first verified run (sha1 is the gate until then)
ROM_CRC32="" # TODO: fill after first verified run

# --- Step 1: ROM identity gate -------------------------------------------
echo "==> [1/5] ROM identity gate"
ACTUAL_SHA1="$(sha1sum "$ROM" | cut -d' ' -f1)"
[ "$ACTUAL_SHA1" = "$ROM_SHA1" ] || {
  echo "ERROR: ROM SHA-1 mismatch: got $ACTUAL_SHA1, want $ROM_SHA1" >&2
  echo "Refusing to continue. Supply your own US dump (see README.md)." >&2
  exit 1
}
echo "ROM SHA-1 OK: $ROM_SHA1"

# --- Step 2: stamp runtime configs ----------------------------------------
echo "==> [2/5] Stamping ROM identity into configs"
# TODO: sed @ROM_SHA1@/@ROM_CRC32@ into variants/fomt/game.toml,
# android/game_android.toml, android/app/build.gradle; generate
# src/fomt_rom_identity.h (FOMT_ROM_SHA1 / FOMT_ROM_CRC32).

# --- Step 3: build the decomp (agbcc), md5 must match ---------------------
echo "==> [3/5] Decomp build (skip with --skip-decomp)"
if [ "$SKIP_DECOMP" -eq 0 ]; then
  # Copies the ROM to third_party/fomt/baserom.gba, builds agbcc if absent,
  # runs make; rebuilt ROM md5 must equal retail or abort. A mismatch here
  # does NOT block the port — it means finder-only mode (no symbol import):
  # re-run with --skip-decomp.
  echo "TODO: decomp build + md5 gate (see docs/PROBE.md §9 step 0)"
fi

# --- Step 4: symbol import (only if step 3 passed) ------------------------
echo "==> [4/5] Symbol import"
# arm-none-eabi-readelf -sW/-SW on the decomp ELF + ld map, then:
#   python3 gbarecomp/tools/symbol_import/import_decomp_symbols.py \
#     --id FOMT --name "Harvest Moon: Friends of Mineral Town (USA)" \
#     --syms ... --sections ... --map ... --rom "$ROM" \
#     --out variants/fomt/symbols/
# Skip entirely in finder-only mode.

# --- Step 5: gba_recompile -------------------------------------------------
echo "==> [5/5] gba_recompile"
# Build the recompiler first if absent:
#   cmake -S gbarecomp -B gbarecomp/build
#   cmake --build gbarecomp/build --target gba_recompile -j"$JOBS"
# Then:
#   gbarecomp/build/gba_recompile --rom "$ROM" \
#     --config variants/fomt/game.toml \
#     [--config variants/fomt/symbols/FOMT_symbols.toml] \
#     [--symbols variants/fomt/symbols/imported_symbols.tsv] \
#     [--data-symbols variants/fomt/symbols/imported_data_symbols.tsv] \
#     --out variants/fomt/generated
echo "TODO: wire steps 2-5 once the repo is scaffolded (see docs/PROBE.md §9)"
echo "Done (skeleton). Next: desktop build + GBARECOMP_STRICT_STATIC=1 run."
