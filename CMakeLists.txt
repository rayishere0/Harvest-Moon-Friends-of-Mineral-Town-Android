cmake_minimum_required(VERSION 3.20)
project(FoMTRecomp C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
include(CTest)

# Path to the platform core (submodule at the repo root). Override
# with -DGBARECOMP_ROOT=... for a different layout.
set(GBARECOMP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/gbarecomp"
    CACHE PATH "Path to gbarecomp platform core")

if(NOT EXISTS "${GBARECOMP_ROOT}/CMakeLists.txt")
    message(FATAL_ERROR
        "GBARECOMP_ROOT does not point to a gbarecomp checkout: ${GBARECOMP_ROOT}")
endif()

# Pull in the platform core targets. This makes gbarecomp_runtime,
# gbarecomp_debug, gbarecomp_gba, gbarecomp_armv4t available as links.
add_subdirectory("${GBARECOMP_ROOT}" gbarecomp_build EXCLUDE_FROM_ALL)

# ─────────────────────────────────────────────────────────────────────
# FoMTRecomp — the game binary. Links the statically recompiled guest
# code (variants/fomt/generated/*.cpp) against the runtime libs. Build
# it with tools/regen.sh first (see README), then:
#   cmake -S . -B build-desktop -DCMAKE_BUILD_TYPE=Release
#   cmake --build build-desktop -jN
# ─────────────────────────────────────────────────────────────────────
file(GLOB FOMT_GENERATED_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/variants/fomt/generated/*.cpp")

set(FOMT_RUNTIME_SOURCES
    src/main.cpp
    ${FOMT_GENERATED_SOURCES}
)

# The recompiler normally emits kDispatchTable/kDispatchTableLen in
# generated/. Until regen produces them, link the engine's empty stubs so
# the scaffold binary still builds and boots headless.
if(NOT FOMT_GENERATED_SOURCES)
    list(APPEND FOMT_RUNTIME_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/scaffold_dispatch_stub.cpp")
endif()

# On Android the shared library must be named `main` (libmain.so is what
# SDLActivity loads); desktop keeps the executable.
if(ANDROID)
    set(FOMT_TARGET main)
    add_library(${FOMT_TARGET} SHARED ${FOMT_RUNTIME_SOURCES})
else()
    set(FOMT_TARGET FoMTRecomp)
    add_executable(${FOMT_TARGET} ${FOMT_RUNTIME_SOURCES})
endif()

target_include_directories(${FOMT_TARGET} PRIVATE
    "${GBARECOMP_ROOT}/src/armv4t"
    "${GBARECOMP_ROOT}/src/gba"
    "${GBARECOMP_ROOT}/src/runtime"
    "${GBARECOMP_ROOT}/src/debug"
    src
)

target_link_libraries(${FOMT_TARGET} PRIVATE
    # --start-group/--end-group lets ld re-iterate the gbarecomp static
    # libs to resolve their mutual references.
    "-Wl,--start-group"
    gbarecomp_runtime
    gbarecomp_debug
    gbarecomp_gba
    gbarecomp_armv4t
    "-Wl,--end-group"
)

target_compile_definitions(${FOMT_TARGET} PRIVATE
    GBARECOMP_DEFAULT_DEBUG_PORT=19843
    GBARECOMP_WINDOW_TITLE="FoMTRecomp"
    GBARECOMP_DEFAULT_GAME_CONFIG="variants/fomt/game.toml"
)

# The generated shards are enormous single TUs (hundreds of recompiled
# functions each). Host compiles of the game binary stay at the build
# type's default, but the guest shards build -O1 -g0: runtime speed
# difference is negligible next to the interpreter, and peak compiler
# memory drops several-fold — which matters on 4 GB machines (and this
# project's build host).
foreach(shard ${FOMT_GENERATED_SOURCES})
    set_property(SOURCE ${shard} PROPERTY COMPILE_OPTIONS "-O1;-g0")
endforeach()

if(MSVC)
    target_link_options(${FOMT_TARGET} PRIVATE /STACK:268435456)
elseif(MINGW OR WIN32 OR CMAKE_SYSTEM_NAME STREQUAL "MSYS")
    target_link_options(${FOMT_TARGET} PRIVATE -Wl,--stack,268435456)
endif()
