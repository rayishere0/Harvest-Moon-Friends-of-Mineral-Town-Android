# Harvest Moon: Friends of Mineral Town — Android (native port)

A **native** Android port of the 2003 GBA game *Harvest Moon: Friends of
Mineral Town* (US), built by **static recompilation** with
[mstan/gbarecomp](https://github.com/mstan/gbarecomp): the ROM's ARM/Thumb
machine code is translated once into native C++ and linked against a
shared GBA hardware runtime. No emulator core, no interpreter at runtime,
no shipped `.gba` ROM.

## Hard constraint

**Native port only.** The shipped build must pass `GBARECOMP_STRICT_STATIC=1`
on desktop first (`COVERAGE: FULLY_STATIC`, zero interpreted instructions,
zero dispatch misses). On Android there is no toolchain, so any coverage
hole would fall back to the interpreter bridge — that is not a shippable
state, however loudly it is logged.

## Status (2026-11-21 gbarecomp probe)

**Recomp-shaped, not decomp-shaped.** The earlier probe found StanHash/fomt
only ~2.6% decompiled and called the project multi-year; the gbarecomp
probe reverses that: the function finder discovers functions from the ROM
itself (Wario Land 4: 32,804 functions from 4,086 seeds; Mega Man Zero
ships with zero decomp input), so the decomp is an optional symbol source,
not a gate. What replaces it as the work: static-coverage iteration
(finder + TOML hints + strict-mode abort loop), three runtime gaps
(mosaic unimplemented in the PPU; raster-split mechanism to verify;
SRAM routines copied to the stack and executed there), and Android
packaging already proven by Wario Land 4.

Full record: `docs/PROBE.md` (this directory's probe write-up).

## License

- The gbarecomp engine is **PolyForm Noncommercial 1.0.0** (+
  `PERMISSIONS.md`): free releases only — donations and ads are OK, but
  no paid APK, subscriptions, paid early access, or paid content. The
  `LICENSE` + `PERMISSIONS.md` statements must travel with the code. No
  sublicensing. Commercial use needs a separate licence from the engine
  author. Two engine files (`bios_hle`) are MPL-2.0.
- This repo's own code (shell, configs, scripts, patches) has no licence
  chosen yet — there is no `LICENSE` file until Ray picks one.
- The ROM, BIOS dump, and generated C++ are **never redistributed**:
  each builder regenerates them from their own dump. The public APK
  contains no ROM/BIOS — the player supplies both at first-run setup
  (SHA-1/size verified).

## What you need (your own dumps — never download these)

- Harvest Moon: Friends of Mineral Town (USA), SHA-1
  `a2fc3574f0a65a4fcf7682fb274b9d7eebdef963`.
- A GBA BIOS dump (required even with BIOS HLE on).

## First steps

0. Upstream sanity (Windows): MSYS2 + devkitARM + `notyourav/agbcc`
   branch `cp`; place your ROM as `baserom.gba` in a StanHash/fomt
   checkout; `make compare` → OK. A fail here does NOT block the port —
   it just means finder-only mode (no decomp symbols).
1. `tools/fetch-upstream.sh` — pins gbarecomp + fomt.
2. `tools/regen.sh --rom <your ROM>` — ROM gate → stamp identity →
   decomp build + md5 (if step 0 passed) → symbol import → `gba_recompile`
   → `variants/fomt/generated/`.
3. Desktop build + strict-static run (see `docs/PROBE.md` §9):
   ```
   cmake -S . -B build-desktop -DCMAKE_BUILD_TYPE=Release
   cmake --build build-desktop -j4
   GBARECOMP_STRICT_STATIC=1 ./build-desktop/FoMTRecomp --no-window --frames 3600
   ```
   Pass prints `self_heal_coverage=FULLY_STATIC`; a miss prints
   `NOT_STATIC` and writes `recomp_master_misses_A4NE.toml.frag` with
   the missing PCs — add them as `[[extra_func]]` / `[[jump_table]]`
   hints in `variants/fomt/game.toml`, re-run `tools/regen.sh`, rebuild,
   re-run. Run from the repo root (game.toml paths resolve relative to
   the TOML file). SDL2 is optional for the headless run; install it
   for a window (MSYS2: `mingw-w64-x86_64-SDL2`).
4. Android APK via `android/app/build.gradle` (see `docs/PROBE.md` §7).
