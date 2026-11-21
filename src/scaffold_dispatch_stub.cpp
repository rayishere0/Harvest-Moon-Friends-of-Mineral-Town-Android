// scaffold_dispatch_stub.cpp — empty guest dispatch table.
//
// Compiled only when no generated guest shards exist yet (see CMakeLists).
// Every PC lookup misses and lands in runtime_dispatch_miss, which fails
// loudly — correct behaviour for a scaffold with no recompiled game code.
// After tools/regen.sh runs, the recompiler emits the real kDispatchTable
// and this file drops out of the build.
//
// Shape verified against pinned gbarecomp (f23317f):
// src/armv4t/native_program.h — DispatchEntry { uint32_t addr; uint8_t
// thumb; uint8_t resume; void (*fn)(void); }, and runtime_arm.cpp declares
// `extern "C" const DispatchEntry kDispatchTable[]` / kDispatchTableLen.

struct DispatchEntry {
    unsigned int addr;
    unsigned char thumb;
    unsigned char resume;
    void (*fn)(void);
};

extern "C" const DispatchEntry kDispatchTable[] = {
    {0xFFFFFFFFu, 0u, 0u, nullptr},
};
extern "C" const unsigned kDispatchTableLen = 1u;
