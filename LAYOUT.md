# Repo layout (recomp-shaped)

```
Harvest-Moon-Friends-of-Mineral-Town-Android/
  README.md                # native-only constraint, status, first steps
  LICENSE                  # this repo's own code (e.g. MIT, Ray's choice)
  gbarecomp/               # pinned SUBMODULE (PolyForm Noncommercial 1.0.0)
  recomp-ui/               # vendored/submodule, MIT (pre-boot launcher)
  tools/
    fetch-upstream.sh      # pins: gbarecomp rev + fomt b8471ae06
    regen.sh               # ROM gate → stamp → decomp+md5 → symbols → recompile
    import-fomt-symbols.sh # readelf + import_decomp_symbols.py (only if decomp matches)
  variants/fomt/
    game.toml              # entry seeds, [[extra_func]], [[data_range]],
                           # [[jump_table]], [[code_copy]], [save], [bios]
    game_android.toml      # Android runtime variant
    symbols/               # imported_symbols.tsv etc. (only if decomp matches)
    generated/             # gitignored build output, NEVER committed
  src/
    main.cpp               # ~150-line shell (WL4 analogue)
    fomt_rom_identity.h    # regen-generated (SHA-1/CRC32)
    fomt_song_classes.h    # only if Music/SFX split mute is wanted
  android/
    app/build.gradle       # applies gbarecomp-app.gradle, gbaGame map
    game_android.toml
    README.md
  patches/
    engine/                # FoMT-driven engine patches (mosaic!)
    game/                  # ROM-gap tweaks (SRAM stack-copy)
  docs/
    PROBE.md               # gbarecomp probe write-up
  .gitignore               # ROMs, BIOS, generated/, saves, third_party/
```

## What survived from the first scaffold (decomp-shaped)

- Overlay structure (port-only code + fetch scripts; upstream not
  vendored as project code).
- `.gitignore` (ROMs, BIOS, data, `third_party/`, build outputs).
- "User supplies their own ROM, hash-checked" — now with the WL4
  first-run setup flow (SAF picker + SHA-1/size verification) instead
  of a build-time-only gate. The user also supplies their own BIOS dump.
- SRAM save sizing (32 KiB, 2 slots; slot count still to pin: 2 vs 3).

## What was replaced

- Decomp-first phasing → coverage-first phasing (finder + TOML hints +
  strict-mode abort loop until `FULLY_STATIC`).
- `native/shim/` (custom tile renderer, m4a/PSG audio, VBlank pump,
  BIOS SWIs, DMA, SRAM file) → the gbarecomp runtime IS the shim.
  Do not write a second one.
- `native/game/` (hand-written ARM64 game code) → `generated/`
  (gitignored build output from `gba_recompile`).
- `native/data/` (user-ROM extraction pipeline) → deleted. Data stays
  in the player's ROM file at runtime; the runtime loads it behind the
  bus. No extraction pipeline is needed or wanted.
- "Fake GBA address space for hardcoded pointers" → deleted. The
  runtime's bus IS the GBA address space.

## Phasing

0. Upstream sanity (`make compare` on the decomp; fail = finder-only).
1. Scaffold the repo (this layout, submodule pins, fetch scripts).
2. First translation run (finder-only first; + symbols if step 0 passed).
   Measure coverage.
3. Coverage iteration until `FULLY_STATIC` on desktop (title → new game
   → first in-game day). Android only after that.
4. Runtime gaps: mosaic (engine PPU work); raster-split verification
   via oracle diffs; SRAM stack-copy patch/HLE; SWI 0x2A clarification.
5. Android packaging + device validation.
6. Later, optional: decomp contributions, widescreen (deferred — raster
   split complicates it), content mods, link play.
