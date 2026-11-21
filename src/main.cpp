// main.cpp — FoMTRecomp entry point.
//
// Thin shell over mstan/gbarecomp (pinned f23317f): the runtime IS the GBA
// hardware shim (PPU, APU/m4a, DMA, timers, interrupts, SRAM, BIOS SWIs).
// No second shim, no hand-written game code — the guest is the generated
// shards in variants/fomt/generated/ (tools/regen.sh output, gitignored).
//
// ROM identity is baked in by tools/regen.sh step 2
// (src/fomt_rom_identity.h: FOMT_ROM_SHA1 / FOMT_ROM_CRC32).
//
// Deliberately NOT copied from the Wario Land 4 reference shell:
//  - no recomp-ui pre-boot launcher (not in this repo; no GBAGAME_RECOMP_UI)
//  - no widescreen view (native 240x160; LAYOUT.md defers widescreen — the
//    raster split complicates it, so max_view_width stays the 240 default)
//  - no MP2K split mute (FoMT's song-table addresses are unknown; the m4a
//    SoundMainRam overlay is still unproven — first regen run decides it)
//  - no content-mods dir (no such field exists in pinned gbarecomp's
//    RunOptions; mods are phasing step 6, not this shell)

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "fomt_rom_identity.h"
#include "mobile_platform.h"
#include "runtime.h"

#ifndef GBARECOMP_DEFAULT_GAME_CONFIG
#define GBARECOMP_DEFAULT_GAME_CONFIG "variants/fomt/game.toml"
#endif

namespace {

void print_usage() {
    std::printf(
        "FoMTRecomp [--bios <path>] [--rom <path>] [game.toml]\n"
        "The BIOS and ROM must match the SHA-1 identities in game.toml.\n"
        "Headless coverage check: GBARECOMP_STRICT_STATIC=1 "
        "./FoMTRecomp --no-window --frames 3600 --tcp 0\n"
        "then read the self_heal_coverage line (FULLY_STATIC vs "
        "NOT_STATIC) and, on a miss, recomp_master_misses_A4NE.toml.frag\n"
        "(A4NE = this ROM's header game code) plus "
        "recomp_coverage_A4NE.json.\n");
}

}  // namespace

int fomt_main(int argc, char** argv) {
    std::vector<std::string> args(argv, argv + argc);
    // Android: private-storage layout, log file, staged game TOML, no
    // pre-boot launcher (shared gbarecomp mobile setup). No-op on desktop.
    gbarecomp::MobileProcessOptions mobile;
    mobile.game_config = GBARECOMP_DEFAULT_GAME_CONFIG;
    mobile.program_name = "./FoMTRecomp";
    gbarecomp::mobile_prepare_process(args, mobile);

    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "--help") == 0 ||
            std::strcmp(argv[i], "-h") == 0) {
            print_usage();
            return 0;
        }
    }

    gbarecomp::RunOptions opts;
    opts.builtin_game_name = "Harvest Moon: Friends of Mineral Town";
    opts.builtin_rom_sha1 = FOMT_ROM_SHA1;
    opts.builtin_rom_crc32 = FOMT_ROM_CRC32;
    opts.launcher_region = "USA";
    opts.launcher_game_config = GBARECOMP_DEFAULT_GAME_CONFIG;
    // Inert until a launcher exists (the runtime never reads the
    // launcher_* fields itself). Mirrors WL4 so the save lands in
    // saves/fomt_usa.sav once the launcher arrives; without one, the
    // desktop save defaults to a .sav next to the ROM.
    // SRAM save, 32 KiB (game.toml [save]: sram, 32768).
    opts.launcher_save_path = "saves/fomt_usa.sav";
#if defined(__ANDROID__)
    opts.ui_touch_friendly = true;
#endif

    std::vector<char*> av;
    av.reserve(args.size());
    for (auto& arg : args) av.push_back(arg.data());
    return gbarecomp::run_game(static_cast<int>(av.size()), av.data(), opts);
}

#if defined(__ANDROID__)
extern "C" int SDL_main(int argc, char** argv) {
    // Desktop-sized host stack for recompiled code (see mobile_platform.h).
    return gbarecomp::mobile_run_with_stack(fomt_main, argc, argv);
}
#else
int main(int argc, char** argv) {
    return fomt_main(argc, argv);
}
#endif
