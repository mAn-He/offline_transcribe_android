cmake_minimum_required(VERSION 3.22)
project(whisper_core)

add_library(whisper STATIC
    ggml.c
    whisper.cpp
)

target_compile_definitions(whisper PRIVATE
    GGML_USE_ACCELERATE=0
    GGML_USE_OPENBLAS=0
    GGML_USE_CLBLAST=0
)

target_include_directories(whisper PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
