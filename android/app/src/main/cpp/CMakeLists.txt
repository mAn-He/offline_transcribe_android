cmake_minimum_required(VERSION 3.22)
project(whisper_ffi)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---------------------------------------------------------------------------
# Fetch the real whisper.cpp at build time. This means we do NOT have to commit
# the (large) ggml/whisper sources into this repo; the NDK build pulls a pinned
# release and compiles it for arm64-v8a. whisper.cpp's own CMake auto-enables
# ARM NEON / dotprod / fp16 optimizations for the target, so we get the ARM
# acceleration the README promised "for free" and tuned per-arch.
# ---------------------------------------------------------------------------
include(FetchContent)

# Build options for the vendored whisper/ggml (set before MakeAvailable).
set(WHISPER_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP            OFF CACHE BOOL "" FORCE)  # NDK has no OpenMP by default

FetchContent_Declare(
  whisper_cpp
  GIT_REPOSITORY https://github.com/ggml-org/whisper.cpp.git
  GIT_TAG        v1.7.4            # pin a known-good release; bump deliberately
  GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(whisper_cpp)

# Our thin C ABI shim.
add_library(whisper_ffi SHARED whisper_c_api.cpp)

find_library(log-lib log)

# whisper.cpp exposes the `whisper` target and its public include dir.
target_link_libraries(whisper_ffi PRIVATE whisper ${log-lib})

target_compile_options(whisper_ffi PRIVATE -O3 -DNDEBUG -fvisibility=hidden)
